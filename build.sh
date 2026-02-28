#!/bin/bash -e

digit="[0-9]"
digits="$digit+"
pat="$digits(\.$digits){2}"

shopt -s extglob
number="+($digit)"
version=$(ls -v v$number.$number.$number.diff 2> /dev/null | tail -1 | sed -E "s/v($pat)\.diff/\1/")

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

depends="cmake ninja pv"

for d in $depends; do
	install $d
done

for d in $compiler $depends; do
	type -f $d &> /dev/null || { echo "Please rerun this script after restarting Haiku"; exit 1; }
done

project=llvm-project
source=$project-$version.src

uri=https://github.com/llvm/$project/releases/download/llvmorg-$version
tarball=$source.tar.xz
test -e $tarball || wget -N $uri/$tarball

if [ -e $project ]; then
	echo "Please rerun this script after removing $project"
	exit 1
fi

mkdir $project
cd $project

echo "Extracting the source"
pv ../$tarball | tar xJf - $source/{clang,cmake,llvm,third-party} --strip-components=1

echo
patch -p1 -r - < ../v$version.diff
echo

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
	-DCLANG_ENABLE_STATIC_ANALYZER=OFF \
	-DCMAKE_BUILD_TYPE=Release \
	-DLLVM_APPEND_VC_REV=OFF \
	-DLLVM_BUILD_TOOLS=OFF \
	-DLLVM_ENABLE_PROJECTS=clang \
	-DLLVM_INCLUDE_BENCHMARKS=OFF \
	-DLLVM_INCLUDE_EXAMPLES=OFF \
	-DLLVM_TARGETS_TO_BUILD=host

ninja -C $dir clang-format
