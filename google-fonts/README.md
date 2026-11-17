# Google Fonts: install the common ones with one double-click

Installs 16 popular Google Fonts families on your Mac. Every font file is already in this folder, so the installer needs no internet and downloads nothing.

Fonts our documents use, like **Inter**, aren't part of Office or macOS. Without them, Word, PowerPoint and Pages swap in another font, and a file that came from Google Docs looks different on your Mac.

## What's included

| Sans serif | Serif | Monospace | Chinese |
|---|---|---|---|
| Inter, Roboto, Open Sans, Lato, Montserrat, Poppins, Noto Sans, Source Sans 3, Nunito, Raleway, Work Sans, DM Sans | Merriweather, Playfair Display | Roboto Mono | Noto Sans SC (Simplified Chinese) |

Every family comes with all its weights and italics. Most are variable fonts: one file holds every weight, and the app's font menu lists them by name (Regular, Medium, Bold and so on).

## Install

1. Get the repo: `git clone https://github.com/jaredhong-citcon/team-tools.git`, or click **Code → Download ZIP** on GitHub and unzip it.
2. Open the `google-fonts` folder and double-click **Install Fonts.command**. A Terminal window lists each family as it installs.
3. Quit and reopen Word, PowerPoint, Pages or Keynote.

It installs for your user only, into `~/Library/Fonts/Team Tools Fonts`. No admin password is needed. A family you already have, from anywhere, is skipped, so nothing is duplicated or replaced. The window shows where it found the existing copy. Files named like `Inter[opsz,wght].ttf` came from Google. Running it again is safe.

**If macOS says it can't verify the file** (this happens with the ZIP download, not with `git clone`): click **Done**. Then open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to the file's name. You only need to do this once per file.

**If it opens as text instead of running:** in Terminal, run `chmod +x` followed by a space, drag the `.command` files into the window, and press Return. Then double-click again.

## Optional: get the latest versions from Google

Double-click **Get Latest from Google.command**. It downloads each family from Google's font repository ([github.com/google/fonts](https://github.com/google/fonts)) and:

- **updates** a family this tool installed, when Google has a newer version. The old files go to the Trash;
- **installs** a family that's missing on your Mac;
- **skips** a family you installed some other way, so you never end up with two copies.

Every downloaded file is checked against GitHub's own hash and must declare the right family name. If anything doesn't match, that family is left as it was.

It needs internet. GitHub allows about 60 requests an hour from one network without a login, and one run makes 17, so in a busy office a run can stop with "hourly limit reached". Try again an hour later. The plain installer above never has this problem, and the versions in this folder are the ones we've tested.

## Uninstall

Double-click **Uninstall Fonts.command**. It moves `~/Library/Fonts/Team Tools Fonts` to the Trash: everything this tool installed, and nothing else.

## Updating later

- **With this tool:** run **Get Latest from Google.command** whenever you like.
- **With a download from fonts.google.com:** run **Uninstall Fonts.command** first, then install Google's files. If you skip this step, you'll have two copies of the same family, and Font Book shows a duplicate warning. To fix it, open Font Book, select the family, and choose **Resolve Duplicates**. Install only the variable files from Google's ZIP, not the ones in its `static` folder: the static files add more entries to your font menu.

Your documents aren't affected either way. They name the family (`Inter`), and every copy provides it.

## Using the fonts in documents

Pick the family name (`Inter`) and set the weight with Bold or the font menu's style list. Never pick a weight as if it were a font, like `Inter SemiBold`: Pages can't find it and swaps it. [doc-fontcheck](../doc-fontcheck/) checks a file for this.

People who don't have these fonts still see a substitute. If you send a file outside the team, a PDF is safer.

## For maintainers

- `families.txt` lists the families, and both `update_fonts.sh` and **Get Latest** read it.
- `update_fonts.sh` refreshes the `fonts` folder from Google's repository. It pins one commit, checks every file's hash and family name, and replaces the folder only if every family passes. It also writes the commit to `fonts/SOURCE.txt`.
- **To add a family:** add a line to `families.txt`, run `./update_fonts.sh`, then run `"./Install Fonts.command" --dry-run`. Keep the set small, because every family adds to the repo's size for everyone.
- `common.sh` holds the shared code. It uses only tools every Mac has, so no git, Python or Homebrew is needed.

## License

The scripts are MIT (see [LICENSE](../LICENSE)). The fonts are not: each family keeps its own license, the SIL Open Font License 1.1, in `OFL.txt` inside its folder. That license lets us share the fonts as they are, together with the license. It doesn't allow selling the fonts on their own.
