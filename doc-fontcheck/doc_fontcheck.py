#!/usr/bin/env python3
"""Check that every font a .docx/.pptx/.xlsx file asks for is a real font family on this Mac.

Why: Apple Pages and Word for Mac look fonts up by family name. A weight written as a family
("Inter SemiBold", "Montserrat Medium") is not found, so Pages asks "Choose which fonts to
replace" or swaps the font quietly. Files that went through Google Docs often have names like that.

Usage:
  doc_fontcheck.py FILE [FILE ...]            print the result; exit 1 if any problem
  doc_fontcheck.py --report FILE [FILE ...]   also save the result as a text file and open it
                                              (for the Finder Quick Action)
"""
import os
import re
import subprocess
import sys
import tempfile
import time
import zipfile

WEIGHT_WORDS = (r'(Thin|Hairline|ExtraLight|UltraLight|Light|Book|Medium|SemiBold|Semibold|DemiBold'
                r'|ExtraBold|UltraBold|Black|Heavy)')
# Names Office writes as defaults or symbol fonts; they don't need checking.
IGNORE = {'', 'Times New Roman', 'Symbol', 'Wingdings', 'Courier New', 'Arial Unicode MS'}
# Office fonts every Word user has. Pages and LibreOffice swap them quietly, without a prompt.
OFFICE_FONTS = {'calibri', 'calibri light', 'cambria', 'cambria math', 'aptos', 'aptos display',
                'aptos narrow', 'consolas', 'segoe ui', 'candara', 'constantia', 'corbel'}
OFFICE_EXT = {'.docx', '.docm', '.dotx', '.pptx', '.pptm', '.potx', '.xlsx', '.xlsm', '.xltx'}


def mac_families():
    """Font families installed on this Mac, lower-cased."""
    fams = set()
    js = ('ObjC.import("AppKit"); '
          'ObjC.deepUnwrap($.NSFontManager.sharedFontManager.availableFontFamilies).join("\\n")')
    out = subprocess.run(['/usr/bin/osascript', '-l', 'JavaScript', '-e', js],
                         capture_output=True, text=True).stdout
    fams |= {line.strip().lower() for line in out.splitlines() if line.strip()}
    try:  # fontconfig (what LibreOffice uses), if installed
        out = subprocess.run(['fc-list', ':', 'family'], capture_output=True, text=True).stdout
        fams |= {f.strip().lower() for line in out.splitlines() for f in line.split(',')}
    except FileNotFoundError:
        pass
    return fams


def font_names(path):
    """Every font name the file's XML asks for."""
    names = set()
    with zipfile.ZipFile(path) as z:
        for part in z.namelist():
            if not part.endswith('.xml'):
                continue
            x = z.read(part).decode('utf-8', 'ignore')
            for tag in re.findall(r'<w:rFonts\b[^>]*>', x):                           # Word runs
                # Only inside <w:rFonts>: <w:lang w:eastAsia="zh-CN"> uses the same attribute names.
                names |= set(re.findall(r'w:(?:ascii|hAnsi|eastAsia|cs)="([^"]+)"', tag))
            names |= set(re.findall(r'<w:font w:name="([^"]+)"', x))                   # Word font table
            names |= set(re.findall(r'<a:(?:latin|ea|cs) typeface="([^"]*)"', x))      # PowerPoint, themes
            names |= set(re.findall(r'<(?:\w+:)?rFont val="([^"]+)"', x))              # Excel rich text
            if part.endswith('styles.xml') and part.startswith('xl/'):
                names |= set(re.findall(r'<(?:\w+:)?name val="([^"]+)"', x))           # Excel cell styles
    # "+mj-lt" and similar are theme placeholders, not fonts.
    return {n for n in names if n not in IGNORE and not n.startswith('+')}


def check(files):
    fams = mac_families()
    lines, problems = [], 0
    for f in files:
        lines.append(f'== {os.path.basename(f)}')
        if os.path.splitext(f)[1].lower() not in OFFICE_EXT:
            lines.append('  skip  not a Word, PowerPoint or Excel file')
            continue
        try:
            names = font_names(f)
        except (zipfile.BadZipFile, OSError) as e:
            lines.append(f'  FAIL  could not open: {e}')
            problems += 1
            continue
        if not names:
            lines.append('  ok    no fonts named')
        for name in sorted(names, key=str.lower):
            issues, note = [], ''
            if re.search(rf'\b{WEIGHT_WORDS}$', name):
                issues.append('a weight written as a family name: use the family and set bold or regular')
            if name.lower() not in fams:
                if name.lower() in OFFICE_FONTS:
                    note = '  (Office font: fine in Word; Pages and LibreOffice swap it quietly)'
                else:
                    issues.append('not installed on this Mac: Pages and Word will swap it')
            problems += bool(issues)
            mark = 'FAIL' if issues else ('info' if note else 'ok  ')
            lines.append(f'  {mark}  {name}' + (f'  <- {"; ".join(issues)}' if issues else note))
    lines.append('')
    lines.append(f'{problems} problem(s) found.' if problems else 'All fonts OK.')
    return '\n'.join(lines), problems


def main(argv):
    report = '--report' in argv
    files = [a for a in argv if a != '--report']
    if not files:
        print(__doc__.strip())
        return 2
    text, problems = check(files)
    print(text)
    if report:
        path = os.path.join(tempfile.gettempdir(), f'Font check {time.strftime("%Y-%m-%d %H%M%S")}.txt')
        with open(path, 'w') as fh:
            fh.write(text + '\n')
        subprocess.run(['/usr/bin/open', '-t', path])
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
