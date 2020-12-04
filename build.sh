#!/bin/bash -e

option=-j

if [ $# -gt 1 -o $# -eq 1 -a "$1" != $option ]; then
	echo Usage: $0 [$option]
	exit 1
fi

version=10.0.1
prefix=https://github.com/llvm/llvm-project/releases/download/llvmorg-$version
suffix=$version.src.tar.xz

wget -N $prefix/llvm-$suffix
wget -N $prefix/clang-$suffix

extract()
{
	mkdir -p $1
	echo Extracting $1 ...
	tar xf $(basename $1)-$suffix -C $1 --strip-components=1 --skip-old-files
}

extract llvm

pattern='^--- a/clang'
diffFile=clang-$version.diff
clangDir=llvm/tools/clang

rm -fv $(grep "$pattern" $diffFile  | sed 's#'"$pattern"'#'$clangDir'#')
extract $clangDir

cd $clangDir
patch -N -p2 -r - < ../../../$diffFile
cd -

if [ -d build ]; then
	cd build
else
	mkdir build
	cd build
	cmake -DCMAKE_BUILD_TYPE=MinSizeRel -G "Unix Makefiles" ../llvm
fi

if [ $# -eq 1 ]; then
	make $option $(nproc) clang-format
else
	make clang-format
fi
