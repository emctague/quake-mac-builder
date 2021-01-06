# quake-mac-builder

This is an environment for compiling and packaging modern ports of Quake I, Quake II, and Quake III Arena
as self-contained macOS apps.

## Using the Apps

All you need to do to use the apps built here is copy certain files from a retail copy of the appropriate game into a particular folder on your machine:

 - For **Quake I**, copy `PAK0.PAK` and `PAK1.PAK` from the `id1` retail folder into `~/Library/Application Support/Quake/id1`.
 - For **Quake II**, copy `pak0.pak`, `pak1.pak`, and `pak2.pak` from the `baseq2` retail folder into `~/Library/Application Support/Quake II/baseq2`.
 - For **Quake III**, copy the files `pak0.pk3` through `pak8.pk3` from the `baseq3` retail folder into `~/Library/Application Support/Quake3/baseq3`.

Place the app in your Applications folder and you're now good to go!



## Building

Invoke `qbuild.sh` from the base directory of this repository to begin compiling. Temporary build files will reside in a `build` directory, and the resulting `.app`s will end up in `out`.

The following environment variables can be set in order to change qbuild.sh's behaviour:

|Variable|Default Value|Purpose|
|--------|-------------|-------|
|`BUILD_QUAKE1`|`true`|When set to `true`, Quake I will be compiled and packaged.|
|`BUILD_QUAKE2`|`true`|When set to `true`, Quake II will be compiled and packaged.|
|`BUILD_QUAKE3`|`true`|When set to `true`, Quake III Arena will be compiled and packaged.|
|`CLEAN_ALL`|`false`|When set to `true`, the entire intermediate build directory will be removed before building.|
|`OBTAIN_VULKAN`|`true`|When set to `true`, a copy of the latest Vulkan SDK for macOS will be downloaded and used during compilation and packaging. Note that this is a slow process, but may be more reliable than using an installed Vulkan SDK.|

