# Team Tools

Small tools for the team, mostly for macOS. Each tool has its own folder with a setup guide.

| Tool | What it does |
|---|---|
| [drive-upload](drive-upload/) | Right-click any file in Finder to upload it to your Google Drive. Never overwrites, and checks each upload by MD5. |
| [pdf-tools](pdf-tools/) | Right-click PDF jobs in Finder: make scans searchable (OCR), merge, split, and convert Office files to PDF. |
| [doc-fontcheck](doc-fontcheck/) | Checks Word, PowerPoint and Excel files for fonts that Pages or Word for Mac will swap, like `Inter SemiBold` from Google Docs. |
| [google-fonts](google-fonts/) | Double-click to install 16 common Google Fonts families, Inter included. Works offline, because the font files are in the repo. An optional second button gets the latest versions from Google. |

## Get the tools

```
git clone https://github.com/jaredhong-citcon/team-tools.git
```

Or click **Code → Download ZIP** on GitHub. Then follow the README in the tool's folder.

## Adding a tool

Each tool gets its own folder with a `README.md` (what it does, setup, troubleshooting) and a row in the table above. Before adding one:

- No personal paths, names or company systems hard-coded. Put settings in a config file with defaults.
- No passwords, tokens or keys, in the code or in examples.
- Test it as a new user would: a clean setup, following only the README.

After pushing, add the tool to the repo description: on GitHub, click the gear next to **About**, or run `gh repo edit --description "..."`. The description lists every tool.

## License

MIT. See [LICENSE](LICENSE). The font files in `google-fonts/fonts/` are the exception: each family keeps its own license (SIL Open Font License), in its folder.
