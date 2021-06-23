#!/bin/bash -e

option=-j

if [ $# -gt 1 -o $# -eq 1 -a "$1" != $option ]; then
	echo Usage: $0 [$option]
	exit 1
fi

version=10.0.1
prefix=https://github.com/llvm/llvm-project/releases/download/llvmorg-$version
suffix=$version.src.tar.xz
llvmTarball=llvm-$suffix
clangTarball=clang-$suffix

test -e $llvmTarball || wget -N $prefix/$llvmTarball
test -e $clangTarball || wget -N $prefix/$clangTarball

extract()
{
	mkdir -p $1
	echo Extracting $1 ...
	tar xf $(basename $1)-$suffix -C $1 --strip-components=1 --skip-old-files
}

test -e llvm || extract llvm

pattern='^--- a/clang'
diffFile=clang-$version.diff
clangDir=llvm/tools/clang
list=$(grep "$pattern" $diffFile  | sed 's#'"$pattern"'#'$clangDir'#')

for file in $list; do
	test -e $file && mv -fv $file $file.old
done

extract $clangDir

cd $clangDir
patch -N -p2 -r - < ../../../$diffFile
cd -

quit=

for file in $list; do
	cmp -s $file.old $file && mv -fv $file.old $file || quit=false
done

if [ -d build ]; then
	cd build
else
	type -f cmake &> /dev/null || echo | pkgman install cmake
	type -f python3 &> /dev/null || echo | pkgman install python3
	mkdir build
	cd build
	cmake -DCMAKE_BUILD_TYPE=MinSizeRel -G "Unix Makefiles" ../llvm
	quit=false
fi

test -z $quit && exit 0

if [ $# -eq 1 ]; then
	make $option $(nproc) clang-format
else
	make clang-format
fi
