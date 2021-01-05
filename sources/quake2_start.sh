#!/bin/bash
CORE="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

export VULKAN_SDK="$CORE"/vulkansdk
export VK_ICD_FILENAMES="$VULKAN_SDK"/macOS/share/vulkan/icd.d/MoltenVK_icd.json
export VK_LAYER_PATH="$VULKAN_SDK"/vulkansdk/macOS/share/vulkan/explicit_layer.d
cd "$HOME/Library/Application Support/Quake II"

exec "$CORE/quake2"
