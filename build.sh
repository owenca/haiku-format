#!/bin/bash -e

version=21.1.5

install()
{
	depend=${2:-$1}
	type -f $1 &> /dev/null || pkgman install -y $depend
}

if [ "$1" = "-s" ]; then
	compiler=clang
	install $compiler llvm${version%%.*}_$compiler
fi

depends="cmake ninja"

for d in $depends; do
	install $d
done

for d in $compiler $depends; do
	type -f $d &> /dev/null || { echo "Please rerun this script after restarting Haiku"; exit; }
done

project=llvm-project
assets="clang cmake llvm third-party"
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

if [ -v compiler ]; then
	options=(
		-DBUILD_SHARED_LIBS=ON \
		-DCMAKE_C_COMPILER=$compiler \
		-DCMAKE_CXX_COMPILER=$compiler++ \
		-DLLVM_USE_LINKER=lld \
	)

	export LIBRARY_PATH=$LIBRARY_PATH:$(pwd)/$dir/lib
fi

cmake -Wno-dev -S llvm -B $dir -G Ninja ${options[@]} \
	-DCMAKE_BUILD_TYPE=Release \
	-DLLVM_ENABLE_PROJECTS=clang \
	-DLLVM_TARGETS_TO_BUILD=X86

ninja -C $dir clang-format
