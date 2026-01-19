#!/bin/bash -e

digit="[0-9]"
digits="$digit+"
pat="$digits(\.$digits){2}"

shopt -s extglob
number="+($digit)"
version=$(ls -v v$number.$number.$number.diff 2> /dev/null | tail -1 | sed -E "s/v($pat)\.diff/\1/")

fileVersion=$version
version=21.1.8

if [[ ! "$version" =~ $pat ]]; then
	echo "Couldn't set up version"
	exit 1
fi

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
	type -f $d &> /dev/null || { echo "Please rerun this script after restarting Haiku"; exit 1; }
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
	exit 1
fi

mkdir -v $project
cd $project

for a in $assets; do
	mkdir -v $a
	echo -n "Extracting $a"
	tar xf ../$(basename $a)-$suffix -C $a --strip-components=1 --checkpoint=.1000
	echo
done

patch -N -p1 -r - < ../v$fileVersion.diff || exit 1

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
