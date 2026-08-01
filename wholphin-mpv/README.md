# MPV build scripts

This scripts are adapted from https://github.com/mpv-android/mpv-android/tree/ae0d956c5a98ab8bf25af7e2c73bcb59e19c15b7/buildscripts licensed MIT.

## Instructions

```bash
cd wholphin-mpv/src/native
./get_dependencies.sh

# Install build dependencies
pip install meson jsonschema

export NDK_PATH=... # Such as ~/Library/Android/sdk/ndk/29.0.14206865
# Build arm64
PATH="$PATH:$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin" ./buildall.sh --clean --arch arm64 mpv
# Build arm32
PATH="$PATH:$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin" ./buildall.sh --arch armv7l mpv
# Build x86_64
PATH="$PATH:$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin" ./buildall.sh --arch x86_64 mpv

cd ../../.. # ie $PROJECT_ROOT
./gradlew build
```

### Dolby Vision P5 on non-certified devices

`wholphin-mpv/src/native/patches/` contains two patches that make Dolby Vision
Profile 5 playback show correct colors on devices whose chips are not Dolby
Vision certified, while keeping hardware decoding:

- `ffmpeg-mediacodec-dovi.patch`: makes FFmpeg's `hevc_mediacodec` wrapper parse
  the Dolby Vision RPU (NAL type 62) and attach `AV_FRAME_DATA_DOVI_METADATA` to
  the output frames, and adds `COLOR_FormatYUV420Flexible` support so the
  no-Surface byte-buffer path works on more devices.
- `mpv-dovi.patch`: forces `mediacodec-copy` (raw IPTPQc2 samples) and
  `vo=gpu-next` (libplacebo DV shader) for Dolby Vision streams, with clear
  fallback warnings when hardware decode or gpu-next is unavailable.

`get_dependencies.sh` applies these patches automatically after cloning FFmpeg
(n8.0) and mpv (v0.41.0). The patches are idempotent (safe to re-run).
