#!/bin/bash

ROOT_PATH=$(realpath .)
TARBALL_PATH=$(realpath ..)/tarball
CRACK_PATH=${ROOT_PATH}/crack
BUILD_MISC_PATH=${ROOT_PATH}/build-misc
BUILD_GCC_PATH=${ROOT_PATH}/build-gcc
BUILD_GLIBC_PATH=${ROOT_PATH}/build-glibc

BINUTILS_VERSION=binutils-2.26
KERNELHEADER_VERSION=linux-4.1.10
GCC_VERSION=gcc-linaro-5.3-2016.02
GLIBC_VERSION=glibc-2.23
MPFR_VR=mpfr-3.1.4
GMP_VR=gmp-6.1.0
MPC_VERSION=mpc-1.0.3
ISL_VERSION=isl-0.14
CLOOG_VERSION=cloog-0.18.1
LINUX_ARCH=arm64
PARALLEL_N=-j4

TARGET=aarch64-QNAP-linux-gnu
CROSS_ROOT_PATH=${ROOT_PATH}/${TARGET}
# CROSS_TOOLS_PATH=${CROSS_ROOT_PATH}/cross-tools
# CROSS_FS_PATH=${CROSS_ROOT_PATH}/fs
CROSS_TOOLS_PATH=${CROSS_ROOT_PATH}
CROSS_FS_PATH=${CROSS_TOOLS_PATH}/${TARGET}
export PATH=${CROSS_TOOLS_PATH}/bin:${PATH}

# --disable-threads --disable-shared
CONFIGURATION_OPTIONS="--disable-multilib"

func_print_char_num() {
	str=$1
	num=$2
	v=$(printf "%-${num}s" "$str")
	echo "${v// /#}"
}

func_show_header()
{
	num=$(expr length "$1")
	num=$(( num + 2 + 8 ))

	func_print_char_num "#" $num
	echo "#    $1    #"
	func_print_char_num "#" $num
}

func_extract_all_tarball()
{
	func_show_header "Extract All Tarball"

	# 1. extract all tarball
	for f in ${TARBALL_PATH}/*.tar*
	do
		tar xf $f;
	done
	
	# 2. link required libraries in gcc directory
	cd ${GCC_VERSION}
	ln -sf ../${MPFR_VR} mpfr
	ln -sf ../${GMP_VR} gmp
	ln -sf ../${MPC_VERSION} mpc
	ln -sf ../${ISL_VERSION} isl
	ln -sf ../${CLOOG_VERSION} cloog
	cd ${ROOT_PATH}
}

func_reset_built_dirs()
{
	func_show_header "Reset Built Directory"

	rm -rf ${BUILD_MISC_PATH} && mkdir -p ${BUILD_MISC_PATH}
	rm -rf ${BUILD_GCC_PATH} && mkdir -p ${BUILD_GCC_PATH}
	rm -rf ${BUILD_GLIBC_PATH} && mkdir -p ${BUILD_GLIBC_PATH}
	rm -rf ${CROSS_TOOLS_PATH} && mkdir -p ${CROSS_TOOLS_PATH}
	rm -rf ${CROSS_FS_PATH} && mkdir -p ${CROSS_FS_PATH}
}

###############
#    build    #
###############

func_binutils()
{
	func_show_header "Binutils"

	cd ${BUILD_MISC_PATH}
	ls -l `pwd`/../${BINUTILS_VERSION}/configure
	../${BINUTILS_VERSION}/configure \
		--prefix=${CROSS_TOOLS_PATH} \
		--with-sysroot \
		--target=${TARGET} \
		--disable-nls \
		--enable-gold --enable-plugins \
		${CONFIGURATION_OPTIONS}
	make ${PARALLEL_N} && make install
}

func_kernel_headers()
{
	func_show_header "Kernel Headers"

	cd ${ROOT_PATH}/${KERNELHEADER_VERSION}
	make mrproper
	make ARCH=${LINUX_ARCH} headers_check
	make ARCH=${LINUX_ARCH} INSTALL_HDR_PATH=${CROSS_FS_PATH} headers_install
	
	cd ${CROSS_FS_PATH}
	rm -rf usr
	ln -sf . usr
}

func_gcc_compiler()
{
	func_show_header "GCC Compiler"

	cd ${BUILD_GCC_PATH}
	../${GCC_VERSION}/configure \
		--prefix=${CROSS_TOOLS_PATH} \
		--with-sysroot=${CROSS_FS_PATH} \
		--target=${TARGET} \
		--enable-languages=c,c++ \
		--enable-tls \
		--disable-nls \
		--enable-c99 \
		--enable-__cxa_atexit \
		--enable-shared \
		--enable-long-long \
		--enable-threads=posix \
		--disable-libgomp \
		--enable-checking=release \
		--with-default-libstdcxx-abi=gcc4-compatible \
		${CONFIGURATION_OPTIONS}
	make ${PARALLEL_N} all-gcc && make install-gcc
}

func_glibc_headers()
{
	func_show_header "GLibc Headers"

	# GLibc (Standard C Library) Headers and Startup Files
	cd ${BUILD_GLIBC_PATH}
	../${GLIBC_VERSION}/configure \
		--prefix= \
		--build=$MACHTYPE \
		--host=${TARGET} \
		--target=${TARGET} \
		--with-binutils=${CROSS_FS_PATH}/bin \
		--with-headers=${CROSS_FS_PATH}/include \
		--disable-profile \
		--enable-obsolete-rpc \
		libc_cv_forced_unwind=yes \
		${CONFIGURATION_OPTIONS}
	make install-bootstrap-headers=yes install_root=${CROSS_FS_PATH} install-headers

	# GLibc startup files
	make ${PARALLEL_N} csu/subdir_lib
	install csu/crt1.o csu/crti.o csu/crtn.o ${CROSS_FS_PATH}/lib
	${TARGET}-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${CROSS_FS_PATH}/lib/libc.so
	touch ${CROSS_FS_PATH}/include/gnu/stubs.h
}

func_gcc_library()
{
	func_show_header "GCC Library"

	cd ${BUILD_GCC_PATH}
	make ${PARALLEL_N} all-target-libgcc && make install-target-libgcc
}

func_glibc_library()
{
	func_show_header "GLibc Library"

	cd ${BUILD_GLIBC_PATH} && \
	make ${PARALLEL_N} user-defined-trusted-dirs="/usr/lib:/lib64:/usr/local/lib" \
		localedir="/usr/lib/locale" i18ndir="/usr/share/i18n"
	make install_root=${CROSS_FS_PATH} install
}

func_gcc_plus_library()
{
	show_header "C++ Library"
	cd ${BUILD_GCC_PATH} && \
	make ${PARALLEL_N} && make install
}

func_link_unlink_library()
{
	local lib_list=(libc.so.6 libc_nonshared.a ld-linux-aarch64.so.1 libpthread.so.0 libpthread_nonshared.a)

	# looking for ${CROSS_FS_PATH}/lib/libc.so
	# looking for ${CROSS_FS_PATH}/lib/libpthread.so

	case $1 in
	"link")
		for file in "${lib_list[@]}"
		do
			ln -sf ${CROSS_FS_PATH}/lib/${file} /lib/${file}
		done
		;;
	"unlink")
		for file in "${lib_list[@]}"
		do
			rm /lib/${file}
		done
		;;
	esac
}

func_crack()
{
	# for include bits/posix2_lim.h
	local limits_header_path=$(find ${CROSS_TOOLS_PATH} -name limits.h | grep include-fixed)
	if [ ! -z ${limits_header_path} ]; then
		echo "overwrite file"
		echo "  -src: ${CRACK_PATH}/limits.h"
		echo "  -dst: ${limits_header_path}"
		cp ${CRACK_PATH}/limits.h ${limits_header_path}
	fi

	# for ioperm
	local io_header_path=${CROSS_FS_PATH}/include/sys/io.h
	echo "overwrite file"
	echo "  -src: ${CRACK_PATH}/io.h"
	echo "  -dst: ${io_header_path}"
	cp ${CRACK_PATH}/io.h ${io_header_path}
	
	echo "/LinkFS_lib" > ${CROSS_FS_PATH}/etc/ld.so.conf
	ln -sf /wormhole ${CROSS_FS_PATH}/LinkFS_lib
}

main()
{
	# func_extract_all_tarball
	func_reset_built_dirs


	###############
	#    build    #
	###############
	func_link_unlink_library "link"

	func_binutils
	func_kernel_headers

	func_gcc_compiler
	func_glibc_headers
	func_gcc_library
	func_glibc_library
	func_gcc_plus_library

	func_link_unlink_library "unlink"

	func_crack

}

main