# Using `haiku-format` with Linux

Somewhat similar to the build + install process for Haiku, the script `linux-setup.sh` provides a means of building and installing the `haiku-format` tool on an `apt`-based Linux system such as [Debian](https://www.debian.org/) or [Ubuntu](https://ubuntu.com/). See the main [`README.md`](README.md) file for general background about `haiku-format`.

## Building and installing

### Installed files

The `haiku-format` files will be installed at `/opt/haiku-format`. The following files are installed;

|Files|Description|
|---|---|
|`lib/lib*.so.*`|Library resources for the binary|
|`bin/haiku-format`|a launcher script for `haiku-format`|
|`bin/_haiku-format`|the `haiku-format` native binary|
|`bin/git-haiku-format`|a git command to launch `haiku-format`|

### Build and install steps

1. `git clone https://github.com/owenca/haiku-format`
2. `cd "haiku-format"`
3. `./linux-setup.sh build`
4. `sudo ./linux-setup.sh install`

The installation's `bin` directory must be included in the `PATH` env-var. The following additional line at the end of your `${HOME}/.profile` will ensure that this is configured;

```
export PATH="/opt/haiku-format/bin:${PATH}"
```

Restart your session and ensure that `haiku-format` can be executed by running;

```
haiku-format -h
```

### Clean steps

If you would like to build again from scratch or would like to clean the build resources run;

1. `./linux-setup.sh clean`

### Uninstall steps

1. `sudo ./linux-setup.sh uninstall`

## Usage

You can format a source file by running;

```
haiku-format src/apps/haikudepot/model/Model.cpp
```

From a clone of the Haiku source code you can get a diff between a commit and the current state with;

```
git haiku-format f7d2fc176e09b850909d6608ac60e9b9a6f1bcbc --diff
```

Find out more about other options with `git haiku-format -h`.