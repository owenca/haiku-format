#!/bin/bash -e

# This is a script to perform build and install processes for the `haiku-format` tool on a
# Linux platform. Run the script with no arguments to get usage. See the accompanying
# `linux.md` file for instructions on general use.

set -e
set -o pipefail

script_bin=$0
build_dir="llvm-project/build"
install_dir="/opt/haiku-format"
llvm_version=18.1.8
llvm_project=llvm-project
llvm_base_url="https://github.com/llvm/${llvm_project}/releases/download/llvmorg-${llvm_version}"

function hf_usage()
{
	cat <<EOF
${script_bin}

This script is designed to build the 'haiku-format' tool and install it on an
'apt'-based Linux system.

${script_bin} build
${script_bin} clean
sudo ${script_bin} install
sudo ${script_bin} uninstall

EOF

	exit 1
}

function hf_confirm_yes_no()
{
	while true; do
		read -p "$* [y/n]: " yn
		case $yn in
			[Yy])
			  return 0
			  ;;
			[Nn])
			  echo "aborted" 1>&2
			  return 1
			  ;;
		esac
	done
}

# Detects absent Debian packages that are required for build and install. If there are
# any absent then it will error to the user with the command they are required to run
# to install the missing packages.

function hf_install_dependencies_linux_gnu_apt()
{
	local depends="lld clang cmake ninja-build"
	local missing_depends=()

	for d in $depends; do
		if ! dpkg -s "${d}" &> /dev/null; then
			missing_depends+=("${d}")
		fi
	done

	if [ "${#missing_depends[@]}" -gt 0 ]; then
		echo "ensure that the necessary dependencies are installed before running this script;"
		echo "sudo apt install ${missing_depends[*]}"
		exit 1
	fi
}

# A number of source files have to be downloaded for the build process to work. This
# function will pull those down and then un-pack them into the directory where the
# build will be undertaken.

function hf_download_sources()
{
	local assets="clang cmake llvm third-party"
	local tar_suffix="${llvm_version}.src.tar.xz"
	local tarball

	for a in $assets; do
		tarball="${a}-${tar_suffix}"
		if [ -e "${tarball}" ]; then
			echo "file [${tarball}] exists - can skip download"
		else
			echo "will download [${tarball}]"
			wget -N "${llvm_base_url}/${tarball}"
		fi
	done

	mkdir -v "${llvm_project}"

	for a in $assets; do
		tarball="${a}-${tar_suffix}"
		mkdir -v "${llvm_project}/${a}"
		echo -n "will extract ${a}"
		tar -xf "${tarball}" -C "${llvm_project}/${a}" --strip-components=1 --checkpoint=.1000
		echo
	done
}

# This function will download and unpack the sources and then perform the build. It will
# not proceed if there is already a build product present in the build location.

function hf_build()
{
	if [ -e "${llvm_project}" ]; then
		echo "Please rerun this script after removing ${llvm_project}. You can achieve this by running;"
		echo "${script_bin} clean"
		exit 1
	fi

	hf_install_dependencies_linux_gnu_apt
	hf_download_sources

	local cmake_options="-DBUILD_SHARED_LIBS=ON -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLLVM_USE_LINKER=lld"

	pushd "${llvm_project}"

	patch -N -p1 -r - < "../v${llvm_version}.diff"
	cmake -Wno-dev -S llvm -B "build" -G Ninja ${cmake_options} \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_ENABLE_PROJECTS=clang \
		-DLLVM_TARGETS_TO_BUILD=host
	ninja -C "build" clang-format
	strip -sv "build/bin/clang-format"

	popd

	echo "did perform build"
}

# Removes the downloaded sources and build product from this directory (not the install).

function hf_clean()
{
	if [ -d "llvm-project" ]; then
		echo "deleting [llvm-project]..."
		rm -rf "llvm-project"
		echo "did delete [llvm-project]"
	fi

	for l in ./*.src.tar.xz; do
		rm "${l}"
		echo "deleted [${l}]"
	done

	echo "did perform clean"
}

# Copies the build product and a launch script into place. It will also create a
# little launch script which sets the library path.

function hf_install()
{
	if [ ! -f "${build_dir}/bin/clang-format" ]; then
		echo "Build product to install not found. You can run a build with;"
		echo "${script_bin} build"
		exit 1
	fi

	local install_root

	if [ -f "${install_root}/bin/haiku-format" ]; then
		echo "the program is already installed at [${install_root}]"
		exit 1
	fi

	if [[ $EUID -ne 0 ]]; then
		echo "run install as the root user by using 'sudo'"
		exit 1
	fi

	mkdir -p "${install_dir}/bin"
	mkdir -p "${install_dir}/lib"

	cp -fv ${build_dir}/bin/clang-format "${install_dir}/bin/_haiku-format"
	sed s/clang-format/haiku-format/g llvm-project/clang/tools/clang-format/git-clang-format \
		> "${install_dir}/bin/git-haiku-format"

	cat <<EOF > "${install_dir}/bin/haiku-format"
#!/bin/bash
LD_LIBRARY_PATH="${install_dir}/lib:\${LIBRARY_PATH}"
"${install_dir}/bin/_haiku-format" \$@
EOF

	chmod -v ogu+x "${install_dir}/bin/haiku-format"
	chmod -v ogu+x "${install_dir}/bin/_haiku-format"
	chmod -v ogu+x "${install_dir}/bin/git-haiku-format"

	for f in ${build_dir}/lib/lib*.so.*; do
		if [[ "$f" =~ ^.+/lib(clang|LLVM).+ ]] && ! [[ "$f" =~ ^.+/lib.+Gen.+$ ]]; then
			cp -v "${f}" "${install_dir}/lib"
		fi
	done
}

hf_uninstall()
{
	if [[ $EUID -ne 0 ]]; then
		echo "run uninstall as the root user by using 'sudo'"
		exit 1
	fi

	if [ ! -d "${install_dir}" ]; then
		echo "The program is not installed at [${install_dir}]"
		exit 1
	fi

	if ! hf_confirm_yes_no "remove the haiku-format program from [${install_dir}]"; then
		exit 1
	fi

	rm -rf "${install_dir}"

	echo "did remove the 'haiku-format' program"
}

hf_main()
{
	if [ $# != 1 ]; then
		hf_usage
	fi

	if ! command -v dpkg &> /dev/null; then
		echo "this script [${script_bin}] can only be used with an 'apt' based distribution of linux."
	fi

	local command=$1
	shift

	case "${command}" in
		build)
			hf_build
			;;
		install)
			hf_install
			;;
		uninstall)
			hf_uninstall
			;;
		clean)
			hf_clean
			;;
		*)
			echo "unknown command [$1]" 1>&2
			return 1
	esac
}

hf_main "$@"