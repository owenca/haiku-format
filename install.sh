#!/bin/bash -e

cp -uv _haiku-format ~/config/settings/.haiku-format
cp -uv build/bin/clang-format ~/config/non-packaged/bin/haiku-format
