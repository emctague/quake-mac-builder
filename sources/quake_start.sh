#!/bin/bash
# Quake I startup script
# This is for embedding within the .app, not for your use.

CORE="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
mkdir -p "$HOME/Library/ApplicationSupport/Quake/id1"
cd "$HOME/Library/ApplicationSupport/Quake"


if [ ! -f "id1/PAK0.PAK" ]; then
	osascript -e 'display dialog "To play Quake, copy all .PAK files from your official Quake disk'\''s id1 folder into this app'\''s id1 folder" buttons {"Open id1 Folder"} default button 1 with title "Quake"'
	open -a Finder ./id1
	exit
fi

exec "$CORE/QuakeSpasm" -basedir "$PWD"
