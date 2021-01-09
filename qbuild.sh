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
IMPORT_CERT="${IMPORT_CERT:-false}"
CODESIGN_DEVELOPER="${CODESIGN_DEVELOPER:-Apple Development: ethan@tague.me (SKUN5354JM)}"

echo "-- emctague/quake-mac-builder --"
echo
echo "Will build Quake I         / QuakeSpasm (BUILD_QUAKE1):       ${BUILD_QUAKE1}"
echo "Will build Quake II        / vkQuake2   (BUILD_QUAKE2):       ${BUILD_QUAKE2}"
echo "Will build Quake III Arena / ioquake3   (BUILD_QUAKE3):       ${BUILD_QUAKE3}"
echo "Will clean build folder                 (CLEAN_ALL):          ${CLEAN_ALL}"
echo "Will obtain own Vulkan SDK              (OBTAIN_VULKAN):      ${OBTAIN_VULKAN}"
echo "Will try to sign App                    (DO_CODESIGN):        ${DO_CODESIGN}"
echo "Will try to import cert                 (IMPORT_CERT):        ${IMPORT_CERT}"
echo "CodeSign Certificate                    (CODESIGN_DEVELOPER): ${CODESIGN_DEVELOPER}"


if [  "$CLEAN_ALL" = true ] ; then
	echo 
	echo "--- CLEANING ALL ---"
	rm -rf build
fi

rm -rf out
mkdir -p build out/quake out/quake2 out/quake3


if [  "$IMPORT_CERT" = true ] ; then
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
	
	if [  "$DO_CODESIGN" = false ] ; then
		CSIDENTITY=""
		CSREQUIRED=NO
	else
		CSIDENTITY="${CODESIGN_DEVELOPER}"
		CSREQUIRED=YES
	fi
	
	if [  "$DO_CODESIGN" = true ] ; then
		
		rm -f SDL.framework/.DS_Store SDL.framework/License.rtf SDL.framework/ReadMe.txt SDL.framework/UniversalBinaryNotes.rtf
		
		codesign --deep -f -s "$CODESIGN_DEVELOPER" SDL.framework
		codesign --deep -f -s "$CODESIGN_DEVELOPER" SDL2.framework
		codesign -f -s "$CODESIGN_DEVELOPER" codecs/lib/*
		
	fi
	
	xcodebuild -project QuakeSpasm.xcodeproj -target QuakeSpasm -configuration Release MACOSX_DEPLOYMENT_TARGET=10.15.0 ARCHS=x86_64 -sdk macosx CODE_SIGN_IDENTITY="$CSIDENTITY" CODE_SIGNING_REQUIRED=$CSREQUIRED

	echo "Copying to Quake.app..."
	cp -r build/Release/QuakeSpasm.app "$APP"
	cd $DISTRODIR
	
	echo "Modifying Quake.app..."
	cp "$CODEDIR/sources/quake_start.sh" "$APP/Contents/MacOS/quake_start.sh"
	plutil -replace CFBundleExecutable -string quake_start.sh "$APP/Contents/Info.plist"
	
	# Replace Info.plist
	rm "$APP/Contents/Frameworks/SDL.framework/Resources/Info.plist"
	cp "$CODEDIR/sources/quake_sdlInfo.plist" "$APP/Contents/Frameworks/SDL.framework/Resources/Info.plist"
	
	cp "$CODEDIR/sources/icon-q1.icns" "$APP/Contents/Resources/QuakeSpasm.icns"

	
	chmod +x "$APP/Contents/MacOS/quake_start.sh"
	chmod +x "$APP"
#	
#	if [ "$DO_CODESIGN" = true ] ; then
#		codesign --deep --force -s "$CODESIGN_DEVELOPER" "$APP/Contents/Frameworks/SDL.framework/Versions/Current"
#		codesign --deep --force -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/libvorbisfile.dylib"
#		codesign --deep --force -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/libvorbis.dylib"
#		codesign --deep --force -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/libopusfile.dylib"
#		codesign --deep --force -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/libopus.dylib"
#		codesign --deep --force -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/libogg.dylib"
#		codesign --deep --force -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/libmikmod.dylib"
#		codesign --deep --force -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/libmad.dylib"
#		codesign --deep --force -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/libFLAC.dylib"
#		codesign --deep --force -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/QuakeSpasm"
#		codesign --force -s "$CODESIGN_DEVELOPER" "$APP"
#	fi
	
	hdiutil create $OUTDIR/Quake-tmp.dmg -ov -volname "Quake" -fs HFS+ -srcfolder "$OUTDIR/quake" 
	hdiutil convert $OUTDIR/Quake-tmp.dmg -format UDZO -o "$OUTDIR/Quake.dmg"
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
	cp "$CODEDIR/sources/icon-q2.icns" "$APP/Contents/Resources/AppIcon.icns"
	cp "$CODEDIR/sources/quake2_start.sh" "$APP/Contents/MacOS/quake2_start.sh"
	cp "quake2" "ref_vk.dylib" "baseq2/game.dylib" "$APP/Contents/MacOS"
	cp "$VULKAN_SDK/macOS/lib/libMoltenVK.dylib" "$APP/Contents/MacOS/vulkansdk/macOS/lib/libMoltenVK.dylib"
	cp "$VULKAN_SDK/macOS/lib/libVkLayer_khronos_validation.dylib" "$APP/Contents/MacOS/vulkansdk/macOS/lib/libVkLayer_khronos_validation.dylib"
	cp "$VULKAN_SDK/macOS/lib/libVkLayer_api_dump.dylib" "$APP/Contents/MacOS/vulkansdk/macOS/lib/libVkLayer_api_dump.dylib"
	cp -r "$VULKAN_SDK/macOS/share/vulkan/explicit_layer.d" "$APP/Contents/MacOS/vulkansdk/macOS/share/vulkan/explicit_layer"
	cp -r "$VULKAN_SDK/macOS/share/vulkan/icd.d" "$APP/Contents/MacOS/vulkansdk/macOS/share/vulkan/icd"
	chmod +x "$APP"
	chmod +x "$APP/Contents/MacOS/quake2"
	chmod +x "$APP/Contents/MacOS/quake2_start.sh"
	
	if [  "$DO_CODESIGN" = true ] ; then
			
		xattr -cr "$APP"
#		codesign --deep -f -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/game.dylib"
#		codesign --deep -f -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/quake2"
#		codesign --deep -f -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/ref_vk.dylib"
		codesign --force --deep -s "$CODESIGN_DEVELOPER" "$APP"
	fi
	
	hdiutil create $OUTDIR/Quake2-tmp.dmg -ov -volname "QuakeII" -fs HFS+ -srcfolder "$OUTDIR/quake2" 
	hdiutil convert $OUTDIR/Quake2-tmp.dmg -format UDZO -o "$OUTDIR/Quake2.dmg"
	rm -rf $OUTDIR/Quake2-tmp.dmg
	
	echo "Done building Quake II!"
fi


if [ "$BUILD_QUAKE3" = true ] ; then
	build_prep "Quake III Arena" ioq3 https://github.com/ioquake/ioq3 quake3
	
	echo "Compiling..."
	make release
	
	echo "Moving app..."
	cp -r build/release-darwin-x86_64/ioquake3.app "$APP"
	
	cp "$CODEDIR/sources/icon-q3.icns" "$APP/Contents/Resources/quake3_flat.icns"

	
	if [  "$DO_CODESIGN" = true ] ; then
		xattr -cr "$APP"

		codesign --deep -f -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/ioquake3"
		codesign --deep -f -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/ioq3ded"
		codesign --deep -f -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/"*.dylib
		codesign --deep -f -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/missionpack/"*.dylib
		codesign --deep -f -s "$CODESIGN_DEVELOPER" "$APP/Contents/MacOS/baseq3/"*.dylib


		codesign --force --deep -s "$CODESIGN_DEVELOPER" "$APP"
	fi
	
	hdiutil create $OUTDIR/Quake3-tmp.dmg -ov -volname "QuakeIIIArena" -fs HFS+ -srcfolder "$OUTDIR/quake3" 
	hdiutil convert $OUTDIR/Quake3-tmp.dmg -format UDZO -o $OUTDIR/Quake3.dmg
	rm -rf $OUTDIR/Quake3-tmp.dmg
	
	echo "Done building Quake III Arena!"
fi