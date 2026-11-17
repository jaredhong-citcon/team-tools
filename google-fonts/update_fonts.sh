#!/bin/bash
# For maintainers only: refresh the bundled fonts in ./fonts from Google's font repository
# (github.com/google/fonts), for the families in families.txt. Team members never need this.
#
# Usage: ./update_fonts.sh    replaces ./fonts only if every family downloads and checks out
# Then test with "Install Fonts.command --dry-run", check the diff, and commit.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/common.sh"
OUT="$HERE/fonts"

# Pin every download to one commit, so the set is consistent and traceable.
# The first "sha" in the reply is the commit's own.
SHA=$(curl -fsS "$GITHUB_API/commits/main" | grep -m1 '"sha"' | sed 's/.*"sha": *"\([0-9a-f]*\)".*/\1/')
[ ${#SHA} = 40 ] || { echo "Couldn't read the latest commit of google/fonts."; exit 1; }
echo "google/fonts commit $SHA"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
while IFS='|' read -r dir fam; do
  fetch_family "$dir" "$fam" "$SHA" "$TMP/$fam"; rc=$?
  [ $rc = 2 ] && { echo "GitHub's hourly limit reached. Try again later."; exit 1; }
  [ $rc != 0 ] && { echo "Failed on $fam. Nothing changed."; exit 1; }
  echo "  $fam: $(ls "$TMP/$fam" | wc -l | tr -d ' ') files"
done < <(family_list "$HERE/families.txt")

printf 'Fonts downloaded from https://github.com/google/fonts at commit %s on %s.\nEach folder holds one family and its license (OFL.txt).\n' \
  "$SHA" "$(date +%Y-%m-%d)" > "$TMP/SOURCE.txt"
rm -rf "$OUT" && mv "$TMP" "$OUT" && chmod 755 "$OUT"
trap - EXIT
echo "Done: $(du -sh "$OUT" | cut -f1) in $OUT"
