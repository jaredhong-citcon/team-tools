# Font Check: will this Office file look right in Pages and Word?

Checks every font a Word, PowerPoint or Excel file asks for, and flags the ones that won't display as intended on a Mac.

## Why

Apple Pages and Word for Mac find fonts by **family name**, like `Inter` or `Montserrat`. Files that went through Google Docs often name a single weight as if it were a family, like `Inter SemiBold`. Pages can't find that, so it asks you to replace fonts or swaps them without telling you. The same happens with fonts that simply aren't installed.

## What it reports

For each file, one line per font:

- **`ok`**: installed on this Mac, and named correctly.
- **`info`**: a standard Office font such as Calibri or Aptos. Fine in Word. Pages and LibreOffice swap it quietly.
- **`FAIL`**: a weight written as a family name, or a font that isn't installed. The line says which.

It exits with code 1 if any line is `FAIL`, so you can use it in scripts.

## Setup

It needs Python 3. macOS offers to install it the first time you run `python3`.

Get the repo first (`git clone https://github.com/jaredhong-citcon/team-tools.git`, or **Code → Download ZIP** on GitHub). Then, from its `doc-fontcheck` folder:

```
mkdir -p ~/bin
cp doc_fontcheck.py ~/bin/
chmod +x ~/bin/doc_fontcheck.py
```

## Use it

```
~/bin/doc_fontcheck.py ~/Desktop/proposal.docx ~/Desktop/deck.pptx
```

Example output:

```
== proposal.docx
  ok    Arial
  info  Calibri  (Office font: fine in Word; Pages and LibreOffice swap it quietly)
  FAIL  Inter SemiBold  <- a weight written as a family name: use the family and set bold or regular

1 problem(s) found.
```

**To fix a FAIL:** open the file, select the text that uses that font, and choose the family (`Inter`) with the weight set by Bold or by the font menu's style list. For a missing font, install it or pick another one.

## Optional: Finder Quick Action

1. Open **Shortcuts**. Go to **Settings → Advanced** and turn on **Allow Running Scripts**.
2. Create a new shortcut named **Check Fonts**. In its details (the ⓘ panel), turn on **Use as Quick Action**, tick **Finder**, and set it to receive **Files**.
3. Add **Run Shell Script**, with Shell: `zsh`, Input: `Shortcut Input`, Pass Input: `as arguments`, and this script:
   `/usr/bin/python3 "$HOME/bin/doc_fontcheck.py" --report "$@"`
4. Right-click Office files in Finder → **Quick Actions → Check Fonts**. The result opens in TextEdit.

## Limits

- It checks the fonts on **your** Mac. Someone without a font you have will still see it swapped.
- A font listed in the file's font table but never used still shows up. It's harmless, but you may see extra `FAIL` lines for files made in LibreOffice.

## License

MIT. See [LICENSE](../LICENSE).
