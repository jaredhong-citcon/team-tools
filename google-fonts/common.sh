# Shared by the scripts in this folder; not run on its own.
# Uses only tools every Mac has: no git, Python or Homebrew needed.

DEST="$HOME/Library/Fonts/Team Tools Fonts"   # everything this tool installs, and nothing else
GITHUB_API="https://api.github.com/repos/google/fonts"
GITHUB_RAW="https://raw.githubusercontent.com/google/fonts"

# Font families this Mac already has, as Pages and Word see them, lower-cased, one per line.
installed_families() {
  /usr/bin/osascript -l JavaScript -e 'ObjC.import("AppKit"); ObjC.deepUnwrap($.NSFontManager.sharedFontManager.availableFontFamilies).join("\n")' 2>/dev/null \
    | tr '[:upper:]' '[:lower:]'
}

# Lines of families.txt as "dir|family", without comments and blank lines.
family_list() { grep -v -e '^#' -e '^[[:space:]]*$' "$1"; }

# Regex for the family name as macOS's file index records it. It stores the default style's
# family, so a variable font may show as "Montserrat Thin" or "DM Sans 9pt": accept the
# family name followed only by weight or size words.
family_re() {
  printf '^%s( (Thin|Hairline|ExtraLight|UltraLight|Light|Regular|Book|Medium|SemiBold|DemiBold|Bold|ExtraBold|UltraBold|Black|Heavy|Italic|[0-9]+pt))*$' \
    "$(printf %s "$1" | sed 's/[.[\*^$]/\\&/g')"
}

# Where an installed family's files are, using Spotlight's font index (outside this tool's folder).
# The source can't be proven, but names tell: Google's files look like "Inter[opsz,wght].ttf".
where_is() {
  /usr/bin/mdfind -onlyin "$HOME/Library/Fonts" -onlyin /Library/Fonts -attr com_apple_ats_name_family \
      "com_apple_ats_name_family == '$1*'" 2>/dev/null \
    | awk '/com_apple_ats_name_family = \($/ { sub(/   com_apple_ats_name_family = \($/, ""); p=$0; next }
           p != "" { v=$0; gsub(/^ *"?|"? *$/, "", v); print v "\t" p; p="" }' \
    | grep -v '/Team Tools Fonts/' | awk -F '\t' -v re="$(family_re "$1")" '$1 ~ re { print $2; exit }' \
    | sed "s|^$HOME|~|" | grep . || printf 'built into macOS or an app'
}

# The family name a font file declares (its default style), read by macOS's own importer.
file_family() {
  /usr/bin/mdimport -t -d2 "$1" 2>&1 | awk '/"com_apple_ats_name_family" =/ { getline; gsub(/^[ \t]*"?|"?,?[ \t]*$/, ""); print; exit }'
}

# Git's hash of a file, to check downloads against google/fonts' own hashes.
blob_sha() {
  { printf 'blob %s\0' "$(stat -f%z "$1")"; cat "$1"; } | shasum -a 1 | cut -d' ' -f1
}

# fetch_family <dir in google/fonts> <family> <ref> <out dir>
# Downloads the family's font files and license into <out dir>, checks each file's hash and family
# name, and returns 0 only if all is well. Returns 2 if GitHub's hourly limit is reached.
fetch_family() {
  local dir="$1" fam="$2" ref="$3" out="$4" json code list blob name url got re
  json=$(mktemp)
  code=$(curl -sS -m 30 -w '%{http_code}' -o "$json" "$GITHUB_API/contents/$dir?ref=$ref") || code=000
  if [ "$code" = 403 ] || [ "$code" = 429 ]; then rm -f "$json"; return 2; fi
  if [ "$code" != 200 ]; then
    echo "    couldn't list $dir on GitHub (HTTP $code)"; rm -f "$json"; return 1
  fi
  # Font files and the license only (not METADATA.pb, DESCRIPTION, FONTLOG or articles).
  list=$(/usr/bin/osascript -l JavaScript -e 'function run(a) {
    return JSON.parse(a[0]).filter(f => f.type === "file" &&
      (/\.(ttf|otf)$/.test(f.name) || ["OFL.txt", "LICENSE.txt", "UFL.txt"].includes(f.name)))
      .map(f => f.sha + " " + f.name).join("\n") }' "$(cat "$json")" 2>/dev/null)
  rm -f "$json"
  printf '%s\n' "$list" | grep -qE '\.(ttf|otf)$' || { echo "    no font files in $dir"; return 1; }
  printf '%s\n' "$list" | grep -qE ' (OFL|LICENSE|UFL)\.txt$' || { echo "    no license file in $dir"; return 1; }
  mkdir -p "$out"
  re=$(family_re "$fam")
  while read -r blob name; do
    url="$GITHUB_RAW/$ref/$dir/$(printf %s "$name" | sed 's/\[/%5B/g; s/\]/%5D/g')"
    curl -fsSg -m 300 -o "$out/$name" "$url" || { echo "    download failed: $name"; return 1; }
    [ "$(blob_sha "$out/$name")" = "$blob" ] || { echo "    file doesn't match GitHub's hash: $name"; return 1; }
    case "$name" in *.ttf|*.otf)
      got=$(file_family "$out/$name")
      printf '%s\n' "$got" | grep -qE "$re" || { echo "    $name says it's \"$got\", not $fam"; return 1; } ;;
    esac
  done <<< "$list"
  return 0
}
