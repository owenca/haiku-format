#!/bin/bash -e

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
list=$(grep "$pattern" $diffFile | sed 's#'"$pattern"'#'$clangDir'#')

for file in $list; do
	test -e $file && mv -fv $file $file.old
done

extract $clangDir

cd $clangDir
patch -N -p2 -r - < ../../../$diffFile
cd -

build=

for file in $list; do
	cmp -s $file.old $file && mv -fv $file.old $file || build=true
done

if [ ! -d build ]; then
	for f in cmake ninja; do
		type -f $f &> /dev/null || pkgman install -y $f || exit 1
	done

	for f in cmake ninja; do
		type -f $f &> /dev/null ||
		( echo 'Please rerun this script after restarting Haiku'; exit )
	done

	cmake -S llvm -B build -G Ninja -DCMAKE_BUILD_TYPE=MinSizeRel -Wno-dev
	build=true
fi

if [ "$build" -o ! -x build/bin/clang-format ]; then
	cd build
	ninja clang-format && strip -s bin/clang-format
fi
