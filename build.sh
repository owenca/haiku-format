#!/bin/bash -e

depends='cmake ninja'

for d in $depends; do
	type -f $d &> /dev/null || pkgman install -y $d || exit
done

for d in $depends; do
	type -f $d &> /dev/null || { echo 'Please rerun this script after restarting Haiku.'; exit; }
done

project=llvm-project
version=18.1.8
assets='clang cmake llvm third-party'
prefix=https://github.com/llvm/$project/releases/download/llvmorg-$version
suffix=$version.src.tar.xz

for a in $assets; do
	tarball=$a-$suffix
	test -e $tarball || wget -N $prefix/$tarball
done

if [ -e $project ]; then
	echo "Please rerun this script after removing $project"
	exit
fi

mkdir -v $project
cd $project

for a in $assets; do
	mkdir -v $a
	echo -n "Extracting $a"
	tar xf ../$(basename $a)-$suffix -C $a --strip-components=1 --checkpoint=.1000
	echo
done

patch -N -p1 -r - < ../v$version.diff || :

dir=build
cmake -Wno-dev -S llvm -B $dir -G Ninja -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_SKIP_RPATH=On
ninja -C $dir clang-format
strip -sv $dir/bin/clang-format
