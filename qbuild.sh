#!/bin/bash

set -e

function build_prep() {
	echo
	echo "--- BUILDING: $1 ---"
	echo
	
	echo "Cloning or updating repository..."
	if [ ! -d $2 ] ; then 
		git clone $3 $2
	fi
	cd $2
	git fetch
		
	APP="$OUTDIR/$1.app"
}

function use_latest_tag() {
	TAG=$(git describe --tags)
	echo "Checking out tag ${TAG}..."
	git checkout ${TAG}
}

BUILD_QUAKE1="${BUILD_QUAKE1:-true}"
BUILD_QUAKE2="${BUILD_QUAKE2:-true}"
BUILD_QUAKE3="${BUILD_QUAKE3:-true}"
CLEAN_ALL="${CLEAN_ALL:-false}"
OBTAIN_VULKAN="${OBTAIN_VULKAN:-true}"

echo "-- emctague/quake-mac-builder --"
echo
echo "Will build Quake I         / QuakeSpasm (BUILD_QUAKE1):  ${BUILD_QUAKE1}"
echo "Will build Quake II        / vkQuake2   (BUILD_QUAKE2):  ${BUILD_QUAKE2}"
echo "Will build Quake III Arena / ioquake3   (BUILD_QUAKE3):  ${BUILD_QUAKE3}"
echo "Will clean build folder                 (CLEAN_ALL):     ${CLEAN_ALL}"
echo "Will obtain own Vulkan SDK              (OBTAIN_VULKAN): ${OBTAIN_VULKAN}"


if [  "$CLEAN_ALL" = true ] ; then
	echo 
	echo "--- CLEANING ALL ---"
	rm -rf build
fi

rm -rf out
mkdir -p out build

CODEDIR="$PWD"
cd out
OUTDIR="$PWD"
cd ../build
BUILDDIR="$PWD"


if [ "$BUILD_QUAKE1" = true ] ; then
	build_prep "Quake I" quakespasm https://github.com/sezero/quakespasm.git 
	use_latest_tag 
	cd MacOSX
	
	echo "Compiling..."
	xcodebuild -project QuakeSpasm.xcodeproj -target QuakeSpasm -configuration Release MACOSX_DEPLOYMENT_TARGET=11.1.99 ARCHS=x86_64 CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -sdk macosx

	echo "Copying to Quake.app..."
	cp -r build/Release/QuakeSpasm.app "$APP"
	cd $DISTRODIR
	
	echo "Modifying Quake.app..."
	cp "$CODEDIR/sources/quake_start.sh" "$APP/Contents/MacOS/quake_start.sh"
	plutil -replace CFBundleExecutable -string quake_start.sh "$APP/Contents/Info.plist"
	
	echo "Done building Quake I!"
fi

if [ "$BUILD_QUAKE2" = true ] ; then
	build_prep "Quake II" vkQuake2 https://github.com/kondrak/vkQuake2
	use_latest_tag 
	
	if [ "$OBTAIN_VULKAN" = true ] ; then
		echo "Downloading Vulkan SDK..."
		curl -O https://sdk.lunarg.com/sdk/download/latest/mac/vulkan_sdk.dmg
		echo "Attaching Vulkan SDK..."
		hdiutil attach -mountpoint "/Volumes/VulkanSDK" vulkan_sdk.dmg
		echo "Copying Vulkan SDK files..."
		mkdir vulkansdk
		cp -r /Volumes/VulkanSDK/* vulkansdk
		echo "Detaching Vulkan SDK..."
		hdiutil detach "/Volumes/VulkanSDK"
		
		export VULKAN_SDK="$PWD"/vulkansdk
		export VK_ICD_FILENAMES="$VULKAN_SDK"/macOS/share/vulkan/icd.d/MoltenVK_icd.json
		export VK_LAYER_PATH="$VULKAN_SDK"/macOS/share/vulkan/explicit_layer.d
	fi
	
	echo "Patching Source to use game dyld from executable directory..."
	git apply "$CODEDIR/sources/q2dyld.patch"
	
	echo "Compiling..."
	cd macos
	make release-xcode
	cd vkQuake2
	
	echo "Creating Quake II.app"
	mkdir -p "$APP/Contents/MacOS/vulkansdk/macOS/{lib,share/vulkan},Resources}"
	cp "$CODEDIR/sources/Quake2Info.plist" "$APP/Contents/Info.plist"
	cp "$CODEDIR/sources/Quake2Icon.icns" "$APP/Contents/Resources/AppIcon.icns"
	cp "$CODEDIR/sources/quake2_start.sh" "$APP/Contents/MacOS/quake2_start.sh"
	cp "quake2" "ref_vl.dylib" "baseq2/game.dylib" "$APP/Contents/MacOS"
	cp "$VULKAN_SDK/LICENSE.txt" "$APP/Contents/MacOS/vulkansdk/LICENSE.txt"
	cp "$VULKAN_SDK/macOS/lib/libMoltenVK.dylib" "$APP/Contents/MacOS/vulkansdk/macOS/lib/libMoltenVK.dylib"
	cp "$VULKAN_SDK/macOS/lib/libVkLayer_khronos_validation.dylib" "$APP/Contents/MacOS/vulkansdk/macOS/lib/libVkLayer_khronos_validation.dylib"
	cp "$VULKAN_SDK/macOS/lib/libVkLayer_api_dump.dylib" "$APP/Contents/MacOS/vulkansdk/macOS/lib/libVkLayer_api_dump.dylib"
	cp "$VULKAN_SDK/macOS/share/vulkan/explicit_layer.d" "$APP/Contents/MacOS/vulkansdk/macOS/share/vulkan/explicit_layer.d"
	cp "$VULKAN_SDK/macOS/share/vulkan/icd.d" "$APP/Contents/MacOS/vulkansdk/macOS/share/vulkan/icd.d"
	chmod +x "$APP"
	
	echo "Done building Quake II!"
fi


if [ "$BUILD_QUAKE3" = true ] ; then
	build_prep "Quake III Arena" ioq3 https://github.com/ioquake/ioq3
	use_latest_tag 
	
	echo "Compiling..."
	./make-macosx.sh x86_64
	
	echo "Moving app..."
	cp -r build/release-darwin/x86_64/ioquake3.app "$APP"
	
	echo "Done building Quake III Arena!"
fi