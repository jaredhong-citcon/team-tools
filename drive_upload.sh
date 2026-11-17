#!/bin/zsh
# drive_upload.sh: upload files or folders to one folder in your own Google Drive, using rclone.
# Run it from a Finder Quick Action (see README.md) or by hand:
#   drive_upload.sh [--dry-run] <file-or-folder> ...
#
# Settings are optional. Put any of these lines in ~/.config/drive-upload/config:
#   REMOTE="gdrive"                              # the rclone remote you made with `rclone config`
#   FOLDER="Uploads"                             # the Drive folder to upload into (created if missing)
#   LOG="$HOME/Library/Logs/drive-upload.log"    # where each upload is logged
#
# What it does:
#   - Never overwrites. If the name is already in the folder, it adds " (YYYY-MM-DD HHMM)" before the extension.
#   - Checks every file by MD5 after upload (folders with `rclone check`).
#   - Skips .DS_Store files.
#   - Shows a notification when done and writes one log line per item.

REMOTE="gdrive"
FOLDER="Uploads"
LOG="$HOME/Library/Logs/drive-upload.log"
CONF="$HOME/.config/drive-upload/config"
[[ -r "$CONF" ]] && source "$CONF"

DEST="$REMOTE:$FOLDER"
mkdir -p "${LOG:h}"

DRY=""
[[ "$1" == "--dry-run" ]] && { DRY="--dry-run"; shift; }

log()    { print -r -- "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }
notify() { /usr/bin/osascript -e "display notification \"${2//\"/\\\"}\" with title \"Drive Upload\" subtitle \"${1//\"/\\\"}\"" 2>/dev/null; }

# Quick Actions run with a short PATH, so also look where Homebrew installs rclone.
RCLONE=$(command -v rclone 2>/dev/null)
[[ -z "$RCLONE" ]] && for p in /opt/homebrew/bin/rclone /usr/local/bin/rclone; do [[ -x "$p" ]] && { RCLONE="$p"; break; }; done
[[ -n "$RCLONE" ]] || { notify "rclone not found" "Install it with: brew install rclone"; exit 1; }
$RCLONE listremotes 2>/dev/null | grep -qx "$REMOTE:" \
  || { notify "No rclone remote named $REMOTE" "Run rclone config first (see README)"; exit 1; }

(( $# )) || { notify "Nothing to upload" "No files were passed in."; exit 1; }

# Names already in the Drive folder (top level only).
existing=("${(@f)$($RCLONE lsf "$DEST" --max-depth 1 2>/dev/null)}")
taken() { (( ${existing[(Ie)$1]} || ${existing[(Ie)$1/]} )); }

ok=0; failed=0; names=()
for src in "$@"; do
  name="${src:t}"
  [[ "$name" == ".DS_Store" ]] && continue
  if [[ ! -e "$src" ]]; then log "MISSING $src"; (( failed++ )); continue; fi

  target="$name"
  if taken "$target"; then
    stamp="$(date '+%Y-%m-%d %H%M')"
    if [[ -f "$src" && "$name" == *.* && "$name" != .* ]]; then
      target="${name:r} ($stamp).${name:e}"
    else
      target="$name ($stamp)"
    fi
  fi

  if [[ -d "$src" ]]; then
    out=$($RCLONE copy "$src" "$DEST/$target" --checksum --exclude ".DS_Store" $DRY 2>&1)
    rc=$?
    if (( rc == 0 )) && [[ -z "$DRY" ]]; then
      out2=$($RCLONE check "$src" "$DEST/$target" --one-way --exclude ".DS_Store" 2>&1); rc=$?
      out+=$'\n'"$out2"
    fi
  else
    out=$($RCLONE copyto "$src" "$DEST/$target" --checksum $DRY 2>&1)
    rc=$?
    if (( rc == 0 )) && [[ -z "$DRY" ]]; then
      # Hash with rclone, not /sbin/md5: from a Quick Action, macOS privacy can block md5
      # in Downloads and Documents ("Operation not permitted") while rclone can still read.
      local_md5=$($RCLONE md5sum "$src" 2>&1 | awk '{print $1}')
      remote_md5=$($RCLONE md5sum "$DEST/$target" 2>/dev/null | awk '{print $1}')
      [[ -n "$local_md5" && "$local_md5" == "$remote_md5" ]] \
        || { rc=9; out+=$'\n'"MD5 mismatch: local ${local_md5:-none}, Drive ${remote_md5:-none}"; }
    fi
  fi

  if (( rc == 0 )); then
    (( ok++ )); names+=("$target"); existing+=("$target")
    log "OK${DRY:+ (dry run)} $src -> $FOLDER/$target"
  else
    (( failed++ ))
    log "FAIL($rc) $src -> $FOLDER/$target :: ${out//$'\n'/ | }"
  fi
done

if (( failed )); then
  notify "$ok uploaded, $failed failed" "See $LOG"
  exit 1
elif (( ok == 1 )); then
  notify "Uploaded${DRY:+ (dry run)} to $FOLDER" "${names[1]}"
else
  notify "Uploaded${DRY:+ (dry run)} $ok items to $FOLDER" "${(j:, :)names}"
fi
