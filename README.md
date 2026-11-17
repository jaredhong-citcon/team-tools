# Upload to Drive: Finder right-click upload to your Google Drive

Right-click any file or folder in Finder and choose **Upload to Drive**. It goes into one folder in your own Google Drive. The script:

- never overwrites a file (a repeated name gets the date and time added);
- checks each file after upload, so a broken upload shows as an error;
- shows a notification when it's done.

Setup takes about 10 minutes, once. You need a Mac with Homebrew.

## 1. Install rclone

```
brew install rclone
```

## 2. Connect rclone to your Google Drive

Run `rclone config` in Terminal and answer the prompts:

| Prompt | Answer |
|---|---|
| New remote / edit / quit | `n` |
| name | `gdrive` |
| Storage | type `drive` (Google Drive) |
| client_id, client_secret | press Enter (leave blank) |
| scope | choose **`drive.file`** (rclone can only see files it uploaded itself) |
| service_account_file | press Enter |
| Edit advanced config | `n` |
| Use web browser to authenticate | `y`. Sign in with your work Google account and allow access |
| Configure as a Shared Drive | `n` |
| Keep this remote | `y`, then `q` to quit |

Your Google login is now saved in `~/.config/rclone/rclone.conf`. **Never share that file.**

**Let the script create the Drive folder.** With the `drive.file` scope, rclone can't see a folder you make by hand in Drive. It would create a second folder with the same name.

## 3. Install the script

```
mkdir -p ~/bin
cp drive_upload.sh ~/bin/
chmod +x ~/bin/drive_upload.sh
```

Uploads go to a Drive folder named **Uploads** by default. To use another name, create `~/.config/drive-upload/config` with one line:

```
FOLDER="My Uploads"
```

You can also set `REMOTE=` (if you didn't name the remote `gdrive`) and `LOG=` (default `~/Library/Logs/drive-upload.log`).

## 4. Test it

```
echo test > ~/Desktop/upload-test.txt
~/bin/drive_upload.sh --dry-run ~/Desktop/upload-test.txt   # shows what would happen, uploads nothing
~/bin/drive_upload.sh ~/Desktop/upload-test.txt             # real upload
```

You should get a notification, and the file should appear in Drive under **Uploads**.

## 5. Add the Finder menu item (Shortcuts app)

1. Open **Shortcuts**. Go to **Settings → Advanced** and turn on **Allow Running Scripts**.
2. Create a new shortcut and name it **Upload to Drive**.
3. In the shortcut's details (the ⓘ panel), turn on **Use as Quick Action** and tick **Finder**.
4. Set it to receive **Files and Folders**.
5. Add the action **Run Shell Script** and set:
   - Shell: `zsh`
   - Input: `Shortcut Input`
   - Pass Input: `as arguments`
   - Script: `"$HOME/bin/drive_upload.sh" "$@"`
6. Close the window. In Finder, right-click a file → **Quick Actions → Upload to Drive**.

The first time you upload from Downloads, Documents or Desktop, macOS may ask whether Shortcuts can open files there. Click **Allow**.

## If something goes wrong

- **"rclone not found"**: run `brew install rclone`.
- **"No rclone remote named gdrive"**: run step 2 again, or set `REMOTE=` in the config file to the name you used.
- **"… failed"**: open the log (`~/Library/Logs/drive-upload.log`) for the reason.
- To stop rclone using your Drive: delete the `gdrive` remote with `rclone config`, and remove rclone at <https://myaccount.google.com/permissions>.

## License

MIT. See [LICENSE](LICENSE).
