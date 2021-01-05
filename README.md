# quake-mac-builder

This is an environment for compiling and packaging modern ports of Quake I, Quake II, and Quake III Arena
as self-contained macOS apps.

## Using

Invoke `qbuild.sh` from the base directory of this repository to begin compiling. Temporary build files will reside in a `build` directory, and the resulting `.app`s will end up in `out`.

The following environment variables can be set in order to change qbuild.sh's behaviour:

|Variable|Default Value|Purpose|
|--------|-------------|-------|
|`BUILD_QUAKE1`|`true`|When set to `true`, Quake I will be compiled and packaged.|
|`BUILD_QUAKE2`|`true`|When set to `true`, Quake II will be compiled and packaged.|
|`BUILD_QUAKE3`|`true`|When set to `true`, Quake III Arena will be compiled and packaged.|
|`CLEAN_ALL`|`false`|When set to `true`, the entire intermediate build directory will be removed before building.|
|`OBTAIN_VULKAN`|`true`|When set to `true`, a copy of the latest Vulkan SDK for macOS will be downloaded and used during compilation and packaging. Note that this is a slow process, but may be more reliable than using an installed Vulkan SDK.|

