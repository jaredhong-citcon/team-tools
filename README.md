# Team Tools

Small tools for the team, mostly for macOS. Each tool has its own folder with a setup guide.

| Tool | What it does |
|---|---|
| [drive-upload](drive-upload/) | Right-click any file in Finder to upload it to your Google Drive. Never overwrites, and checks each upload by MD5. |

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

## License

MIT. See [LICENSE](LICENSE).
