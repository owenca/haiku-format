#!/bin/bash -e

depends='cmake ninja'

for d in $depends; do
	type -f $d &> /dev/null || pkgman install -y $d || exit
done

for d in $depends; do
	type -f $d &> /dev/null || { echo 'Please rerun this script after restarting Haiku.'; exit; }
done

version=18.1.8
assets='clang cmake llvm third-party'
prefix=https://github.com/llvm/llvm-project/releases/download/llvmorg-$version
suffix=$version.src.tar.xz

for a in $assets; do
	tarball=$a-$suffix
	test -e $tarball || wget -N $prefix/$tarball
done

mkdir -pv llvm-project
cd llvm-project

extract()
{
	mkdir -pv $1
	echo Extracting $1 ...
	tar xf ../$(basename $1)-$suffix -C $1 --strip-components=1 --skip-old-files
}

for a in $assets; do
	test -e $a || extract $a
done

dir=build
cmake -Wno-dev -S llvm -B $dir -G Ninja -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_SKIP_RPATH=On
patch -N -p1 -r - < ../v$version.diff || :
ninja -C $dir clang-format
strip -sv $dir/bin/clang-format
