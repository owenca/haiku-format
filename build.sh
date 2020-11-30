#!/bin/bash -e

llvmVersion=9.0.1
wget -N https://github.com/llvm/llvm-project/releases/download/llvmorg-$llvmVersion/llvm-$llvmVersion.src.tar.xz
wget -N https://github.com/llvm/llvm-project/releases/download/llvmorg-$llvmVersion/clang-$llvmVersion.src.tar.xz

mkdir -p llvm
echo Extracting llvm ...
tar xf llvm-$llvmVersion.src.tar.xz -C llvm --strip-components=1 --skip-old-files
echo Patching llvm ...
pushd llvm
patch -p1 < ../llvm-$llvmVersion.patchset
popd

mkdir -p llvm/tools/clang
echo Extracting clang ...
tar xf clang-$llvmVersion.src.tar.xz -C llvm/tools/clang --strip-components=1 --skip-old-files
echo Patching clang ...
pushd llvm/tools/clang
patch -p1 < ../../../clang-$llvmVersion.patchset
popd

if [ -d build ]; then
	cd build
else
	mkdir build
	cd build
	cmake -DCMAKE_BUILD_TYPE=MinSizeRel -G "Unix Makefiles" ../llvm
fi

make -j$(nproc) clang-format
ln -fs $PWD/bin/clang-format ../haiku-format
