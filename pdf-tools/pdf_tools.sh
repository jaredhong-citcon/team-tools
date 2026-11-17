#!/bin/zsh
# pdf_tools.sh: everyday PDF jobs, made for Finder Quick Actions (see README.md).
#
#   pdf_tools.sh ocr   <pdf> ...          make scanned PDFs searchable  -> "<name> (searchable).pdf"
#   pdf_tools.sh merge <pdf> <pdf> ...    combine into one PDF, in name order -> "Merged <date time>.pdf"
#   pdf_tools.sh split <pdf> ...          one PDF per page              -> folder "<name> (pages)"
#   pdf_tools.sh topdf <file> ...         Word, Excel, PowerPoint and other documents to PDF -> "<name>.pdf"
#
# Results are saved next to the originals. Nothing is ever overwritten: a taken name gets " 2", " 3", ...
# Settings are optional. Put any of these lines in ~/.config/pdf-tools/config:
#   OCR_LANGS="eng"                            # e.g. "eng+chi_sim" after: brew install tesseract-lang
#   LOG="$HOME/Library/Logs/pdf-tools.log"

OCR_LANGS="eng"
LOG="$HOME/Library/Logs/pdf-tools.log"
CONF="$HOME/.config/pdf-tools/config"
[[ -r "$CONF" ]] && source "$CONF"

# Quick Actions run with a short PATH, so add the places Homebrew installs to.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
SOFFICE="/Applications/LibreOffice.app/Contents/MacOS/soffice"
mkdir -p "${LOG:h}"

log()    { print -r -- "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }
notify() { /usr/bin/osascript -e "display notification \"${2//\"/\\\"}\" with title \"PDF Tools\" subtitle \"${1//\"/\\\"}\"" 2>/dev/null; }
need()   { command -v "$1" >/dev/null || { notify "$1 not found" "Install it with: brew install $2"; exit 1; }; }

# free_path <path-without-extension> <extension or empty>: the first name not already taken.
free_path() {
  local base="$1" ext="${2:+.$2}" p i=2
  p="$base$ext"
  while [[ -e "$p" ]]; do p="$base $i$ext"; (( i++ )); done
  print -r -- "$p"
}

ok=0; failed=0; outs=()
good() { (( ok++ )); outs+=("${2:t}"); log "OK $action $1 -> $2"; }
bad()  { (( failed++ )); log "FAIL $action $1 :: ${2//$'\n'/ | }"; }
is_pdf() { [[ "${1:e:l}" == "pdf" && -f "$1" ]]; }

action="$1"; shift 2>/dev/null
(( $# )) || { notify "Nothing to do" "Usage: pdf_tools.sh ocr|merge|split|topdf <files>"; exit 1; }

case "$action" in
  ocr)
    need ocrmypdf ocrmypdf
    for f in "$@"; do
      is_pdf "$f" || { bad "$f" "not a PDF"; continue; }
      out=$(free_path "${f:r} (searchable)" pdf)
      # --skip-text leaves pages that already have text alone; --output-type pdf keeps it a normal PDF.
      msg=$(ocrmypdf --skip-text --output-type pdf -l "$OCR_LANGS" "$f" "$out" 2>&1)
      (( $? == 0 )) && good "$f" "$out" || { rm -f "$out"; bad "$f" "$msg"; }
    done ;;

  merge)
    need qpdf qpdf
    pdfs=()
    for f in "$@"; do is_pdf "$f" && pdfs+=("$f") || bad "$f" "not a PDF, left out"; done
    pdfs=("${(@on)pdfs}")   # name order, with numbers sorted as numbers (2 before 10)
    if (( ${#pdfs} < 2 )); then
      notify "Pick at least two PDFs" "Merge needs two or more PDF files."; exit 1
    fi
    out=$(free_path "${pdfs[1]:h}/Merged $(date '+%Y-%m-%d %H%M')" pdf)
    msg=$(qpdf --empty --pages "${pdfs[@]}" -- "$out" 2>&1); rc=$?
    # qpdf exit 3 = finished with warnings; the file is still written.
    (( rc == 0 || rc == 3 )) && good "${#pdfs} files" "$out" || { rm -f "$out"; bad "${pdfs[*]}" "$msg"; } ;;

  split)
    need qpdf qpdf
    for f in "$@"; do
      is_pdf "$f" || { bad "$f" "not a PDF"; continue; }
      dir=$(free_path "${f:r} (pages)" "")
      mkdir -p "$dir"
      msg=$(qpdf --split-pages "$f" "$dir/${f:t:r} p%d.pdf" 2>&1); rc=$?
      (( rc == 0 || rc == 3 )) && good "$f" "$dir" || { rm -rf "$dir"; bad "$f" "$msg"; }
    done ;;

  topdf)
    [[ -x "$SOFFICE" ]] || { notify "LibreOffice not found" "Install it with: brew install --cask libreoffice"; exit 1; }
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/pdf_tools.XXXXXX")
    for f in "$@"; do
      [[ -f "$f" ]] || { bad "$f" "not a file"; continue; }
      [[ "${f:e:l}" == "pdf" ]] && { bad "$f" "already a PDF"; continue; }
      # A private LibreOffice profile lets this run even while LibreOffice is open.
      msg=$("$SOFFICE" "-env:UserInstallation=file://$tmp/profile" --headless --convert-to pdf --outdir "$tmp/out" "$f" 2>&1)
      made="$tmp/out/${f:t:r}.pdf"
      if [[ -s "$made" ]]; then
        out=$(free_path "${f:r}" pdf); mv "$made" "$out" && good "$f" "$out"
      else
        bad "$f" "$msg"
      fi
    done
    rm -rf "$tmp" ;;

  *)
    notify "Unknown action: $action" "Use ocr, merge, split or topdf."; exit 1 ;;
esac

if (( failed )); then
  notify "$ok done, $failed failed" "See $LOG"; exit 1
elif (( ok == 1 )); then
  notify "Done: $action" "${outs[1]}"
else
  notify "Done: $action ($ok)" "${(j:, :)outs}"
fi
