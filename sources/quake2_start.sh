#!/bin/bash
CORE="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

export VULKAN_SDK="$CORE"/vulkansdk
export VK_ICD_FILENAMES="$VULKAN_SDK"/macOS/share/vulkan/icd.d/MoltenVK_icd.json
export VK_LAYER_PATH="$VULKAN_SDK"/vulkansdk/macOS/share/vulkan/explicit_layer.d

mkdir -p "$HOME/Library/Application Support/Quake II/baseq2"
cd "$HOME/Library/Application Support/Quake II"

if [ ! -f "baseq2/pak0.pak" ]; then
	osascript -e 'display dialog "To play Quake 2, copy all .pak files from your official Quake II disk'\''s baseq2 folder into this app'\''s baseq2 folder" buttons {"Open baseq2 Folder"} default button 1 with title "Quake II"'
	open -a Finder ./baseq2
	exit
fi

exec "$CORE/quake2"
