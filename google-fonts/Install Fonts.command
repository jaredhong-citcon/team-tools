#!/bin/bash
# Double-click in Finder to install every font family in the "fonts" folder next to this file.
# Offline: it only copies files from this folder. To ~/Library/Fonts/Team Tools Fonts, for your
# user only, with no admin password. A family you already have (from anywhere) is skipped,
# so nothing is duplicated or replaced.
#
# Command line: "./Install Fonts.command" [--dry-run]    --dry-run lists what it would do, changes nothing
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/fonts"
if [ ! -f "$HERE/common.sh" ] || [ ! -d "$SRC" ]; then
  echo "Can't find the files next to this one. Download the whole google-fonts folder, not just this file."
  exit 1
fi
. "$HERE/common.sh"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1

installed=$(installed_families)
added=0; skipped=0; failed=0
for dir in "$SRC"/*/; do
  fam=$(basename "$dir")
  lower=$(printf %s "$fam" | tr '[:upper:]' '[:lower:]')
  if [ -d "$DEST/$fam" ]; then
    echo "  skip     $fam  (installed earlier by this tool)"; skipped=$((skipped+1)); continue
  fi
  if printf '%s\n' "$installed" | grep -qxF "$lower"; then
    echo "  skip     $fam  (already on this Mac: $(where_is "$fam"))"; skipped=$((skipped+1)); continue
  fi
  echo "  install  $fam"
  added=$((added+1))
  [ $DRY = 1 ] && continue
  mkdir -p "$DEST/$fam"
  # Each folder holds only the family's font files and its license.
  # -X: don't copy extended attributes, such as the download quarantine flag.
  if ! cp -X "$dir"* "$DEST/$fam/"; then
    echo "  FAILED   $fam: couldn't copy the files"; rm -rf "$DEST/$fam"; added=$((added-1)); failed=$((failed+1))
  fi
done

echo
if [ $DRY = 1 ]; then
  echo "Dry run: would install $added family(ies), skip $skipped. Nothing changed."
  exit 0
fi
msg="Installed $added font family(ies); $skipped were already installed."
[ $failed -gt 0 ] && msg="$msg $failed failed (see the lines above)."
echo "$msg"
[ $added -gt 0 ] && echo "Quit and reopen Word, PowerPoint, Pages or Keynote to see the new fonts."
/usr/bin/osascript -e "display notification \"$msg\" with title \"Install Fonts\"" 2>/dev/null
echo "You can close this window."
