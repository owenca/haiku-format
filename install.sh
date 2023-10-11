#!/bin/bash -e

cp -v llvm-project/build/bin/clang-format ~/config/non-packaged/bin/haiku-format

config=~/config/settings/.haiku-format
test -f $config && echo "Warning: obsolete config file $config can be deleted!"
