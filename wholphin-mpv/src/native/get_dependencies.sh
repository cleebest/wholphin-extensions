#!/usr/bin/env bash

set -exou pipefail

SCRIPT_PATH="$( dirname "${BASH_SOURCE[0]}" )"
SCRIPT_DIR_ABS="$(cd "$SCRIPT_PATH" && pwd)"
DEPS_PATH="../../$SCRIPT_PATH/build/libmpv/deps"
mkdir -p "$DEPS_PATH"
DEPS_PATH="$(realpath ../../$SCRIPT_PATH/build/libmpv/deps)"

pushd "$DEPS_PATH" || exit

function clone(){
  repo=$1
  branch=$2
  dir=$3
  shift 3

  if [[ -d "$dir" ]]; then
    pushd "$dir" || exit
    git checkout --force "$branch" 2>/dev/null || \
      git checkout --force "refs/tags/$branch" 2>/dev/null || true
    popd || exit
  else
    git clone "$repo" --depth 1 -b "$branch" "$dir" "$@"
  fi
}

function apply_patches(){
  local dir=$1
  local pattern=$2
  local patch_dir
  patch_dir="$SCRIPT_DIR_ABS/patches"
  if [[ ! -d "$patch_dir" ]]; then
    return
  fi
  pushd "$dir" || exit
  for p in "$patch_dir"/$pattern; do
    [[ -f "$p" ]] || continue
    if git apply --check "$p" 2>/dev/null; then
      git apply "$p"
      echo "Applied $p"
    elif git apply --reverse --check "$p" 2>/dev/null; then
      echo "Patch $p already applied, skipping."
    else
      echo "Failed to apply $p" >&2
      exit 1
    fi
  done
  popd || exit
}

clone "https://github.com/videolan/dav1d" "1.5.3" dav1d

clone "https://github.com/FFmpeg/FFmpeg" "n8.1.2" ffmpeg
# Apply local patches for Dolby Vision support in the MediaCodec wrapper.
apply_patches ffmpeg 'ffmpeg-*.patch'

clone "https://gitlab.freedesktop.org/freetype/freetype.git" "VER-2-14-1" freetype2 --recurse-submodules

clone "https://github.com/libass/libass" "0.17.4" libass

clone "https://github.com/haasn/libplacebo" "v7.351.0" libplacebo --recurse-submodules

clone "${MPV_REPO_URL:-https://github.com/cleebest/mpv}" "${MPV_REPO_BRANCH:-wholphin-dovi}" mpv
# Apply local patches for Dolby Vision (mediacodec-copy + gpu-next).
apply_patches mpv 'mpv-*.patch'

if [[ ! -d mbedtls ]]; then
	mkdir mbedtls
	wget https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-3.6.4/mbedtls-3.6.4.tar.bz2 -O - | \
		tar -xj -C mbedtls --strip-components=1
fi

if [[ ! -d fribidi ]]; then
	mkdir fribidi
	wget https://github.com/fribidi/fribidi/releases/download/v1.0.16/fribidi-1.0.16.tar.xz -O - | \
		tar -xJ -C fribidi --strip-components=1
fi

if [[ ! -d harfbuzz ]]; then
	mkdir harfbuzz
	wget https://github.com/harfbuzz/harfbuzz/releases/download/12.1.0/harfbuzz-12.1.0.tar.xz -O - | \
		tar -xJ -C harfbuzz --strip-components=1
fi

version_unibreak="6.1"
if [[ ! -d unibreak ]]; then
	mkdir unibreak
	wget https://github.com/adah1972/libunibreak/releases/download/libunibreak_${version_unibreak//./_}/libunibreak-${version_unibreak}.tar.gz -O - | \
		tar -xz -C unibreak --strip-components=1
fi

if [[ ! -d lua ]]; then
	mkdir lua
	wget https://www.lua.org/ftp/lua-5.2.4.tar.gz -O - | \
		tar -xz -C lua --strip-components=1
fi

# python packages: jsonschema jinja2 meson

popd || exit
