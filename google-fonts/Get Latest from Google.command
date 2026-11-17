#!/bin/bash
# Double-click in Finder to download the newest version of each family in families.txt from
# Google's font repository (github.com/google/fonts) and install it.
# Needs internet. Optional: "Install Fonts.command" works offline with the tested versions in this folder.
#
# - Families this tool installed are replaced when Google has a newer version. The old files go to the Trash.
# - Families missing on this Mac are installed.
# - Families installed some other way are left alone, so you never get two copies.
# Every file is checked against GitHub's hash and must declare the right family name.
#
# Command line: "./Get Latest from Google.command" [--dry-run]    --dry-run downloads and checks, installs nothing
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
if [ ! -f "$HERE/common.sh" ] || [ ! -f "$HERE/families.txt" ]; then
  echo "Can't find the files next to this one. Download the whole google-fonts folder, not just this file."
  exit 1
fi
. "$HERE/common.sh"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1

echo "Checking Google's font repository..."
if ! curl -sS -m 15 -o /dev/null "$GITHUB_API"; then
  echo "Can't reach GitHub. Check your internet connection, or use Install Fonts.command, which works offline."
  exit 1
fi

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
OLD="$HOME/.Trash/Team Tools Fonts (replaced $(date +%Y-%m-%d\ %H%M%S))"
installed=$(installed_families)
added=0; updated=0; current=0; skipped=0; failed=0

while IFS='|' read -r dir fam; do
  lower=$(printf %s "$fam" | tr '[:upper:]' '[:lower:]')
  if [ ! -d "$DEST/$fam" ] && printf '%s\n' "$installed" | grep -qxF "$lower"; then
    echo "  skip     $fam  (installed some other way: $(where_is "$fam"))"; skipped=$((skipped+1)); continue
  fi
  new="$TMP/$fam"
  fetch_family "$dir" "$fam" main "$new"; rc=$?
  if [ $rc = 2 ]; then
    echo "  STOPPED  GitHub's hourly download limit is reached for this network. Try again in an hour."
    failed=$((failed+1)); break
  elif [ $rc != 0 ]; then
    echo "  FAILED   $fam  (kept what you have)"; failed=$((failed+1)); continue
  fi
  if [ -d "$DEST/$fam" ] && diff -rq "$new" "$DEST/$fam" >/dev/null 2>&1; then
    echo "  current  $fam"; current=$((current+1)); continue
  fi
  if [ -d "$DEST/$fam" ]; then
    echo "  update   $fam"; updated=$((updated+1))
  else
    echo "  install  $fam"; added=$((added+1))
  fi
  [ $DRY = 1 ] && continue
  if [ -d "$DEST/$fam" ]; then
    mkdir -p "$OLD" && mv "$DEST/$fam" "$OLD/" 2>/dev/null || rm -rf "$DEST/$fam"   # replaced copies can be downloaded again
  fi
  mkdir -p "$DEST" && mv "$new" "$DEST/$fam"
done < <(family_list "$HERE/families.txt")

echo
if [ $DRY = 1 ]; then
  echo "Dry run: would install $added, update $updated; $current up to date, $skipped skipped, $failed failed. Nothing changed."
  exit 0
fi
msg="Installed $added, updated $updated; $current already up to date, $skipped skipped."
[ $failed -gt 0 ] && msg="$msg $failed failed (see the lines above)."
echo "$msg"
[ $((added+updated)) -gt 0 ] && echo "Quit and reopen Word, PowerPoint, Pages or Keynote to use them."
/usr/bin/osascript -e "display notification \"$msg\" with title \"Get Latest Fonts\"" 2>/dev/null
echo "You can close this window."
