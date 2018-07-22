#!/bin/sh

set -e

cd $(dirname $0)

build() {
	arch=$1
	target=$2
	jni_dir=$3

	echo "Building for $arch"

	tool_prefix=$(grep '^ar' ~/.cargo/config | grep $arch | awk '{print $3}' | sed -e 's,",,g' -e 's,-ar$,,')
	export CC="$tool_prefix-gcc"
	export AR="$tool_prefix-ar"
	cargo +nightly build --target $target

	mkdir -p android/src/main/jniLibs/$jni_dir
	cp ../target/$target/debug/libflouze_flutter.so android/src/main/jniLibs/$jni_dir/
	"$tool_prefix-strip" android/src/main/jniLibs/$jni_dir/libflouze_flutter.so
}

build aarch64-linux-android  aarch64-linux-android    arm64-v8a
build arm-linux-androideabi  armv7-linux-androideabi  armeabi-v7a
build i686-linux-android     i686-linux-android       x86
build x86_64-linux-android   x86_64-linux-android     x86_64