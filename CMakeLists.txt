#
cmake_minimum_required ( VERSION 3.7 )  # for GREATER_EQUAL
cmake_policy( SET CMP0020 NEW )
cmake_policy( SET CMP0042 NEW )
cmake_policy( SET CMP0053 NEW )

project (nanopi-neo)

if (NOT DEFINED CMAKE_SUPPRESS_DEVELOPER_WARNINGS)
  set(CMAKE_SUPPRESS_DEVELOPER_WARNINGS 1 CACHE INTERNAL "No dev warnings")
endif()

list( APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/Modules" )
include (version)

get_filename_component( BUILD_ROOT ${CMAKE_BINARY_DIR} DIRECTORY )

set( CMAKE_ARCHIVE_OUTPUT_DIRECTORY         ${CMAKE_BINARY_DIR}/lib ) # static libs, dll's import lib/exp
set( CMAKE_LIBRARY_OUTPUT_DIRECTORY         ${CMAKE_BINARY_DIR}/lib ) #plugins
set( CMAKE_RUNTIME_OUTPUT_DIRECTORY         ${CMAKE_BINARY_DIR}/bin )  # .exe | .dll

#--- read config.sh ---
file( STRINGS ${CMAKE_SOURCE_DIR}/config.sh configs )
foreach( i ${configs} )
  string( REGEX MATCHALL "[^=]+=.+$" config ${i} )
  string( REGEX REPLACE "([^=]+)=(.+$)" "\\1" key ${i} )
  if ( ${key} MATCHES "^(KERNELRELEASE|BOOST_VERSION|distro|cross_target|target|target_device)$" )
    string( REGEX REPLACE "([^=]+)=(.+$)" "\\2" value ${i} )
    set( ${key} ${value} )
  endif()
endforeach()

set ( MAKE make )
set ( DOWNLOADS $ENV{HOME}/Downloads )
set ( KERNEL_SOURCE ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE} )
set ( UBOOT_BUILD_DIR ${CMAKE_BINARY_DIR}/u-boot-${target_device} )
set ( ROOTFS ${BUILD_ROOT}/arm-linux-gnueabihf-rootfs-${distro} )
set ( TOOLS ${CMAKE_SOURCE_DIR}/scripts )

add_custom_command(
  OUTPUT ${KERNEL_SOURCE}
  COMMAND git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git -b v${KERNELRELEASE} --single-branch ${KERNEL_SOURCE}
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  COMMENT "Fetching linux kernel source.  This will tail a while."
  )

add_custom_command(
  OUTPUT ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE}/.config
  DEPENDS ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE}
  COMMAND ${MAKE} -C ${KERNEL_SOURCE} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- sunxi_defconfig
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE}
  VERBATIM
  )

add_custom_command( 
  OUTPUT ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE}/arch/arm/boot/zImage
  COMMAND ${MAKE} -C ${KERNEL_SOURCE} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 zImage
  COMMAND ${MAKE} -C ${KERNEL_SOURCE} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 dtbs
  COMMAND ${MAKE} -C ${KERNEL_SOURCE} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 all
  DEPENDS ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE}  ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE}/.config
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE}
  )

add_custom_target(
  defconfig
  DEPENDS ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE}/.config
  )

add_custom_target(
  menuconfig
  DEPENDS ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE}/.config
  COMMAND ${MAKE} -C ${KERNEL_SOURCE} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE}  
  )

add_custom_target(
  zImage
  DEPENDS ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE}/arch/arm/boot/zImage
  )

add_custom_target( kernel-source DEPENDS ${KERNEL_SOURCE} )

###################### U-BOOT #########################
include ( u-boot )

set ( IMGFILE
  ${CMAKE_BINARY_DIR}/${target}_${distro}-${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}.${VERSION_TWEAK}-dev.img )

#------------- debian debootstrap ---------------
add_custom_command( 
  OUTPUT ${ROOTFS}
  COMMAND ${MAKE} -f debootstrap.make DISTRO=${distro} TARGETDIR=${ROOTFS} -C ${CMAKE_SOURCE_DIR}/scripts world
  )
add_custom_target( debian DEPENDS ${ROOTFS} )
#------------- end debian rootfs ---------------

add_custom_command(
  OUTPUT ${CMAKE_BINARY_DIR}/boot.scr
  COMMAND mkimage -A arm -O linux -T script -C none -n "nanopi-neo" -d ${CMAKE_SOURCE_DIR}/src/boot.cmd ${CMAKE_BINARY_DIR}/boot.scr
  DEPENDS ${CMAKE_SOURCE_DIR}/src/boot.cmd
  )

add_custom_target( boot.scr DEPENDS ${CMAKE_BINARY_DIR}/boot.scr )

#------------- SDCard image ---------------
set ( SCR ${CMAKE_BINARY_DIR}/boot.scr )
set ( DTB ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE}/arch/arm/boot/dts/sun8i-h3-nanopi-neo.dtb )
set ( DTS ${CMAKE_BINARY_DIR}/linux-${KERNELRELEASE}/arch/arm/boot/dts/sun8i-h3-nanopi-neo.dts )
set ( UBOOT ${UBOOT_BUILD_DIR}/u-boot-sunxi-with-spl.bin )
list ( APPEND BOOT_FILES ${SCR} ${DTB} ${DTS} )
list ( APPEND BOOT_FILES "${KERNEL_SOURCE}/arch/arm/boot/zImage" )
list ( APPEND BOOT_FILES "${KERNEL_SOURCE}/.config" )
set ( bootfs "/mnt/bootfs" )
set ( rootfs "/mnt/rootfs" )
include ( mkimage )

add_custom_target( img ALL DEPENDS ${IMGFILE} ${UBOOT} zImage VERBATIM )
#------------- end SDCard image ---------------

message( STATUS "--------------------------------------------" )
message( STATUS "KERNELRELEASE   = " ${KERNELRELEASE} )
message( STATUS "BOOST_VERSION   = " ${BOOST_VERSION} )
message( STATUS "KERNEL_SOURCE   = " ${KERNEL_SOURCE} )
message( STATUS "UBOOT_BUILD_DIR = " ${UBOOT_BUILD_DIR} )
message( STATUS "UBOOT           = " ${UBOOT} )
message( STATUS "ROOTFS          = " ${ROOTFS} )
message( STATUS "distro          = " ${distro} )
message( STATUS "cross_target    = " ${cross_target} )
message( STATUS "target_device   = " ${target_device} )
message( STATUS "rootfs          = " ${rootfs} )
message( STATUS "bootfs          = " ${bootfs} )
message( STATUS "DOWNLOADS       = " ${DOWNLOADS} )
message( STATUS "IMGFILE         = " ${IMGFILE} )
message( STATUS "BOOT_FILES        " )
foreach( i ${BOOT_FILES} )
  message( STATUS "\t\t${i}" )
endforeach()
message( STATUS "PACKAGES          " )
foreach( i ${PACKAGES} )
  message( STATUS "\t\t${i}" )
endforeach()
message( STATUS "--------------------------------------------" )
