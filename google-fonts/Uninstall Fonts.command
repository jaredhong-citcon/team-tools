#!/bin/bash
# Double-click in Finder to remove the fonts this tool installed (by "Install Fonts.command" or
# "Get Latest from Google.command"). Only ~/Library/Fonts/Team Tools Fonts is touched: it moves
# to the Trash, so you can put it back. Fonts you installed any other way are left alone.
set -u
DEST="$HOME/Library/Fonts/Team Tools Fonts"
if [ ! -d "$DEST" ]; then
  echo "Nothing to remove: no fonts were installed by this tool."
  exit 0
fi

n=$(find "$DEST" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
to="$HOME/.Trash/Team Tools Fonts $(date +%Y-%m-%d\ %H%M%S)"
if mv "$DEST" "$to"; then
  echo "Moved $n font family(ies) to the Trash."
  echo "Quit and reopen Word, PowerPoint, Pages or Keynote to finish."
else
  echo "Couldn't move the folder to the Trash. Opening it, so you can drag it there yourself."
  open "$HOME/Library/Fonts"
fi
echo "You can close this window."
