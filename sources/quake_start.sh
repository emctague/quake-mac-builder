#!/bin/bash
# Quake I startup script
# This is for embedding within the .app, not for your use.

CORE="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
mkdir -p "$HOME/Library/ApplicationSupport/Quake/id1"
cd "$HOME/Library/ApplicationSupport/Quake"
exec "$CORE/QuakeSpasm" -basedir "$PWD"

