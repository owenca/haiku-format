#!/bin/sh -e

wget -N http://releases.llvm.org/6.0.1/llvm-6.0.1.src.tar.xz
wget -N http://releases.llvm.org/6.0.1/cfe-6.0.1.src.tar.xz

mkdir -p llvm
echo Extracting llvm ...
tar xf llvm-6.0.1.src.tar.xz -C llvm --strip-components=1 --skip-old-files

mkdir -p llvm/tools/clang
echo Extracting clang ...
tar xf cfe-6.0.1.src.tar.xz -C llvm/tools/clang --strip-components=1 --skip-old-files

cd src
update.sh
cd ..

if [ ! -d build ]; then
	mkdir build
	cd build
	cmake -G "Unix Makefiles" ../llvm
	cd ..
fi

cd build
make clang-format
ln -fs $PWD/bin/clang-format ../haiku-format
