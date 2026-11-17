# PDF Tools: right-click PDF jobs in Finder

Four Finder Quick Actions for everyday PDF work:

| Quick Action | What it does | Result, saved next to the original |
|---|---|---|
| **Make PDF Searchable** | Reads the text in scanned PDFs (OCR), so you can search and copy it. Pages that already have text are left alone. | `<name> (searchable).pdf` |
| **Merge PDFs** | Combines the selected PDFs into one, in name order (`2` comes before `10`). | `Merged <date time>.pdf` |
| **Split PDF** | Saves each page as its own PDF. | folder `<name> (pages)` |
| **Convert to PDF** | Turns Word, Excel, PowerPoint, text and other documents into PDF, using LibreOffice. | `<name>.pdf` |

Nothing is ever overwritten. If a name is taken, the tool adds ` 2`, ` 3`, and so on. You get a notification when the job finishes.

Setup takes about 10 minutes, once. You need a Mac with Homebrew.

## 1. Install the tools it uses

```
brew install ocrmypdf qpdf
brew install --cask libreoffice      # only needed for Convert to PDF
```

## 2. Install the script

Get the repo first (`git clone https://github.com/jaredhong-citcon/team-tools.git`, or **Code → Download ZIP** on GitHub). Then, from its `pdf-tools` folder:

```
mkdir -p ~/bin
cp pdf_tools.sh ~/bin/
chmod +x ~/bin/pdf_tools.sh
```

## 3. Test it

```
~/bin/pdf_tools.sh ocr   ~/Desktop/some-scan.pdf
~/bin/pdf_tools.sh merge ~/Desktop/a.pdf ~/Desktop/b.pdf
~/bin/pdf_tools.sh split ~/Desktop/a.pdf
~/bin/pdf_tools.sh topdf ~/Desktop/report.docx
```

## 4. Add the Finder menu items (Shortcuts app)

1. Open **Shortcuts**. Go to **Settings → Advanced** and turn on **Allow Running Scripts**.
2. Create a new shortcut for each action you want, named as in the table above.
3. In each shortcut's details (the ⓘ panel), turn on **Use as Quick Action** and tick **Finder**. Set it to receive **Files**, or **PDFs** for the first three.
4. Add the action **Run Shell Script** and set Shell: `zsh`, Input: `Shortcut Input`, Pass Input: `as arguments`. The script line is:

| Quick Action | Script |
|---|---|
| Make PDF Searchable | `"$HOME/bin/pdf_tools.sh" ocr "$@"` |
| Merge PDFs | `"$HOME/bin/pdf_tools.sh" merge "$@"` |
| Split PDF | `"$HOME/bin/pdf_tools.sh" split "$@"` |
| Convert to PDF | `"$HOME/bin/pdf_tools.sh" topdf "$@"` |

5. In Finder, select files, right-click, then choose **Quick Actions** and the action.

The first time you use one on files in Downloads, Documents or Desktop, macOS may ask whether Shortcuts can open files there. Click **Allow**.

## Other languages for OCR

OCR reads English by default. To add Chinese, for example:

```
brew install tesseract-lang
mkdir -p ~/.config/pdf-tools
echo 'OCR_LANGS="eng+chi_sim"' > ~/.config/pdf-tools/config
```

Use `chi_tra` for Traditional Chinese. `tesseract --list-langs` shows every language installed.

## If something goes wrong

- **"… not found"**: install the tool the notification names (step 1).
- **"… failed"**: the log at `~/Library/Logs/pdf-tools.log` gives the reason for each file.
- **Password-protected PDFs** can't be merged, split or made searchable. Remove the password first, for example in Preview.
- **Convert to PDF looks different from the original**: LibreOffice swaps fonts it doesn't have. Install the missing fonts, or print to PDF from Word or PowerPoint instead.

## License

MIT. See [LICENSE](../LICENSE).
