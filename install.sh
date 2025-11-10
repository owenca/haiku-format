#!/bin/bash -e

dir=~/config/non-packaged
bin=$dir/bin

haiku_format=$bin/haiku-format
git_haiku_format=$bin/git-haiku-format

cd llvm-project

cp -fv build/bin/clang-format $haiku_format
strip -sv $haiku_format

sed s/clang-format/haiku-format/g clang/tools/clang-format/git-clang-format > $git_haiku_format
chmod -v +x $git_haiku_format

shopt -s extglob

if [ "$1" = "-s" ]; then
	cd build/lib
	cp -fv lib@(clang|LLVM)!(*Gen*).so.* $dir/lib
fi
