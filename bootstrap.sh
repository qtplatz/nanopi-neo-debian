#!/bin/bash

arch=`uname`-`arch`
cwd=`pwd`
host_system=`uname`
source ./config.sh

source_dir=("$cwd")
build_debug=false
build_clean=false
build_root=$(dirname "$cwd")
config=release
target=nanopi-neo
cmake_args=('-DCMAKE_BUILD_TYPE=Release')

echo "Using Linux " $KERNELRELEASE

while [ $# -gt 0 ]; do
    case "$1" in
	debug|eclipse)
	    echo "*********** building eclipse project ***********"
	    build_debug=true
	    config=debug
	    shift
	    ;;
	clean)
	    shift
	    build_clean=true
	    ;;
	*)
	    break
	    ;;
    esac
done

if [ -z $cross_target ]; then
    case $arch in
	Darwin-*)
	    build_dir=( "$build_root/build-$arch/$target.$config" )
	    if [ $config = debug ]; then
		cmake_args=('-G' 'Xcode' '-DCMAKE_BUILD_TYPE=Debug')
	    fi
	    ;;
	*)
	    build_dir=( "$build_root/build-$arch/$target.$config" )
	    if [ $config = debug ]; then
		cmake_args=('-G' 'CodeLite - Unix Makefiles' '-DCMAKE_BUILD_TYPE=Debug' '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON')
		#cmake_args=('-G' 'Eclipse CDT4 - Unix Makefiles' '-DCMAKE_ECLIPSE_VERSION=4.5' '-DCMAKE_BUILD_TYPE=Debug')
	    fi
	    ;;
    esac
else
    build_dir=( "$build_root/build-$cross_target/$target.$config" )
fi

if [ $build_clean = true ]; then
    echo rm -rf $build_dir
    rm -rf $build_dir
    exit
fi

echo "source_dir       : ${source_dir}"
echo "build_dir        : ${build_dir}"
echo "target           :" $cross_target

# =============== change directory ==============

echo "#" mkdir -p $build_dir
echo "#" cd $build_dir
echo "cd ${build_dir}; cmake -DKERNELRELEASE=$KERNELRELEASE ${source_dir}"

#exit

mkdir -p $build_dir
cd $build_dir
echo "#" pwd `pwd`

if [ -z $cross_target ]; then
    
    echo cmake "${cmake_args[@]}" $source_dir
    cmake "${cmake_args[@]}" $source_dir
    
else
    echo "## Cross build for $arch"
    case $cross_target in
	armhf|arm-linux-gnueabihf)
	    cmake -DCMAKE_TOOLCHAIN_FILE=${cwd}/toolchain-arm-linux-gnueabihf.cmake \
		  -DKERNELRELEASE=$KERNELRELEASE \
		  $source_dir
	    ;;
	*)
	    echo "Unknown cross_target: $cross_target"
	    ;;
    esac    
fi

