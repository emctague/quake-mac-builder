#!/bin/bash

set -e

function build_prep() {
	cd $BUILDDIR
	echo
	echo "--- BUILDING: $1 ---"
	echo
	
	echo "Cloning or updating repository..."
	if [ ! -d $2 ] ; then 
		git clone $3 $2
	fi
	cd $2
	git fetch
	git reset --hard HEAD
		
	APP="$OUTDIR/$4/$1.app"
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
DO_CODESIGN="${DO_CODESIGN:-false}"
CODESIGN_DEVELOPER="Apple Development: ethan@tague.me (SKUN5354JM)"

echo "-- emctague/quake-mac-builder --"
echo
echo "Will build Quake I         / QuakeSpasm (BUILD_QUAKE1):  ${BUILD_QUAKE1}"
echo "Will build Quake II        / vkQuake2   (BUILD_QUAKE2):  ${BUILD_QUAKE2}"
echo "Will build Quake III Arena / ioquake3   (BUILD_QUAKE3):  ${BUILD_QUAKE3}"
echo "Will clean build folder                 (CLEAN_ALL):     ${CLEAN_ALL}"
echo "Will obtain own Vulkan SDK              (OBTAIN_VULKAN): ${OBTAIN_VULKAN}"
echo "Will try to sign App                    (DO_CODESIGN):   ${DO_CODESIGN}"


if [  "$CLEAN_ALL" = true ] ; then
	echo 
	echo "--- CLEANING ALL ---"
	rm -rf build
fi

rm -rf out
mkdir -p build out/quake out/quake2 out/quake3


if [  "$DO_CODESIGN" = true ] ; then
	echo "$P12_BASE64" | base64 --decode > Certificates.p12
	security create-keychain -p "$P12_PASSWORD" MyKeychain
	security default-keychain -s MyKeychain
	security unlock-keychain -p "$P12_PASSWORD" MyKeychain
	security import Certificates.p12 -P "$P12_PASSWORD" -k MyKeychain -T /usr/bin/codesign
	security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$P12_PASSWORD" MyKeychain
	
fi

CODEDIR="$PWD"
cd out
OUTDIR="$PWD"
cd ../build
BUILDDIR="$PWD"

#export CODESIGN_ALLOCATE="/Applications/Xcode.app/Contents/Developer/usr/bin/codesign_allocate"


if [ "$BUILD_QUAKE1" = true ] ; then
	build_prep "Quake I" quakespasm https://github.com/sezero/quakespasm.git quake
	use_latest_tag 
	cd MacOSX
	
	echo "Compiling..."
	xcodebuild -project QuakeSpasm.xcodeproj -target QuakeSpasm -configuration Release MACOSX_DEPLOYMENT_TARGET=10.15.0 ARCHS=x86_64 CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -sdk macosx

	echo "Copying to Quake.app..."
	cp -r build/Release/QuakeSpasm.app "$APP"
	cd $DISTRODIR
	
	echo "Modifying Quake.app..."
	cp "$CODEDIR/sources/quake_start.sh" "$APP/Contents/MacOS/quake_start.sh"
	plutil -replace CFBundleExecutable -string quake_start.sh "$APP/Contents/Info.plist"
	
	if [ "$DO_CODESIGN" = true ] ; then
		codesign --deep -s "$CODESIGN_DEVELOPER" "$APP"
	fi
	
	hdiutil create $OUTDIR/Quake-tmp.dmg -ov -volname "Quake" -fs HFS+ -srcfolder "$OUTDIR/quake" 
	hdiutil convert $OUTDIR/Quake-tmp.dmg -format UDZO -o $OUTDIR/Quake.dmg
	rm -rf $OUTDIR/Quake-tmp.dmg
	
	echo "Done building Quake I!"
fi

if [ "$BUILD_QUAKE2" = true ] ; then
	build_prep "Quake II" vkQuake2 https://github.com/kondrak/vkQuake2 quake2
	use_latest_tag 
	
	if [ "$OBTAIN_VULKAN" = true ] ; then
		echo "Downloading Vulkan SDK..."
		curl -O https://sdk.lunarg.com/sdk/download/latest/mac/vulkan_sdk.dmg
		echo "Attaching Vulkan SDK..."
		hdiutil attach -mountpoint "/Volumes/VulkanSDK" vulkan_sdk.dmg
		echo "Copying Vulkan SDK files..."
		rm -rf vulkansdk
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
	mkdir -p "$APP"/Contents/{MacOS/vulkansdk/macOS/{lib,share/vulkan},Resources}
	cp "$CODEDIR/sources/Quake2Info.plist" "$APP/Contents/Info.plist"
	cp "$CODEDIR/sources/Quake2Icon.icns" "$APP/Contents/Resources/AppIcon.icns"
	cp "$CODEDIR/sources/quake2_start.sh" "$APP/Contents/MacOS/quake2_start.sh"
	cp "quake2" "ref_vk.dylib" "baseq2/game.dylib" "$APP/Contents/MacOS"
	cp "$VULKAN_SDK/LICENSE.txt" "$APP/Contents/MacOS/vulkansdk/LICENSE.txt"
	cp "$VULKAN_SDK/macOS/lib/libMoltenVK.dylib" "$APP/Contents/MacOS/vulkansdk/macOS/lib/libMoltenVK.dylib"
	cp "$VULKAN_SDK/macOS/lib/libVkLayer_khronos_validation.dylib" "$APP/Contents/MacOS/vulkansdk/macOS/lib/libVkLayer_khronos_validation.dylib"
	cp "$VULKAN_SDK/macOS/lib/libVkLayer_api_dump.dylib" "$APP/Contents/MacOS/vulkansdk/macOS/lib/libVkLayer_api_dump.dylib"
	cp -r "$VULKAN_SDK/macOS/share/vulkan/explicit_layer.d" "$APP/Contents/MacOS/vulkansdk/macOS/share/vulkan/explicit_layer.d"
	cp -r "$VULKAN_SDK/macOS/share/vulkan/icd.d" "$APP/Contents/MacOS/vulkansdk/macOS/share/vulkan/icd.d"
	chmod +x "$APP"
	chmod +x "$APP/Contents/MacOS/quake2"
	chmod +x "$APP/Contents/MacOS/quake2_start.sh"
	
	if [  "$DO_CODESIGN" = true ] ; then
		codesign --force -s "$CODESIGN_DEVELOPER" "$APP"
	fi
	
	hdiutil create $OUTDIR/Quake2-tmp.dmg -ov -volname "QuakeII" -fs HFS+ -srcfolder "$OUTDIR/quake2" 
	hdiutil convert $OUTDIR/Quake2-tmp.dmg -format UDZO -o "$OUTDIR/Quake2.dmg"
	rm -rf $OUTDIR/Quake2-tmp.dmg
	
	echo "Done building Quake II!"
fi


if [ "$BUILD_QUAKE3" = true ] ; then
	build_prep "Quake III Arena" ioq3 https://github.com/ioquake/ioq3 quake3
	
	echo "Compiling..."
	./make-macosx.sh x86_64
	
	echo "Moving app..."
	cp -r build/release-darwin-x86_64/ioquake3.app "$APP"
	
	if [  "$DO_CODESIGN" = true ] ; then
		codesign --force -s "$CODESIGN_DEVELOPER" "$APP"
	fi
	
	hdiutil create $OUTDIR/Quake3-tmp.dmg -ov -volname "QuakeIIIArena" -fs HFS+ -srcfolder "$OUTDIR/quake3" 
	hdiutil convert $OUTDIR/Quake3-tmp.dmg -format UDZO -o $OUTDIR/Quake3.dmg
	rm -rf $OUTDIR/Quake3-tmp.dmg
	
	echo "Done building Quake III Arena!"
fi