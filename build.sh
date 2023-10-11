#!/bin/bash -e

depends='cmake ninja'

for d in $depends; do
	type -f $d &> /dev/null || pkgman install -y $d || exit 1
done

for d in $depends; do
	type -f $d &> /dev/null || { echo 'Please rerun this script after restarting Haiku.'; exit; }
done

version=17.0.1
assets='clang cmake llvm third-party'
prefix=https://github.com/llvm/llvm-project/releases/download/llvmorg-$version
suffix=$version.src.tar.xz

for a in $assets; do
	tarball=$a-$suffix
	test -e $tarball || wget -N $prefix/$tarball
done

mkdir -p llvm-project
cd llvm-project

extract()
{
	mkdir -p $1
	echo Extracting $1 ...
	tar xf ../$(basename $1)-$suffix -C $1 --strip-components=1 --skip-old-files
}

for a in $assets; do
	test -e $a || extract $a
done

cmake -S llvm -B build -G Ninja -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_BUILD_TYPE=MinSizeRel -Wno-dev
patch -N -p1 -r - < ../v$version.diff || :

cd build
ninja clang-format && strip -s bin/clang-format
