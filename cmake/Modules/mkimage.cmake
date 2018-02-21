
if ( bootfs STREQUAL "" )
  set ( bootfs "/mnt/bootfs" )
endif()

if ( rootfs STREQUAL "" )
  set ( rootfs "/mnt/rootfs" )
endif()

if ( KERNEL_SOURCE STREQUAL "" )
  message( FATAL_ERROR "Emtpy KERNEL_SOURCE" )
endif()

set ( CP cp )
set ( SUDO sudo )
set ( TAR tar )

# --- generate raw image filesystem on file, loop mount on bootfs, rootfs ---

add_custom_command(
  OUTPUT ${IMGFILE}
  COMMAND ${SUDO} ${TOOLS}/umount-all.sh ${bootfs} ${rootfs} /mnt /a
  COMMAND ${SUDO} ${TOOLS}/detach-all.sh
  COMMAND bootfs=${bootfs} rootfs=${rootfs} ${TOOLS}/mkimage.sh ${IMGFILE} ${UBOOT}
  COMMAND ${SUDO} ${CP} ${BOOT_FILES} ${bootfs}
  COMMAND ${SUDO} ${CP} -ax "${ROOTFS}/*" "${rootfs}"
  COMMAND ${SUDO} ${MAKE} -C ${KERNEL_SOURCE} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 modules_install INSTALL_MOD_PATH=${rootfs}
  COMMAND ${SUDO} ${TOOLS}/network-interface.sh
  COMMAND echo "-- generating post-install script on ${rootfs} ---"  
  COMMAND ${SUDO} KERNELRELEASE='${KERNELRELEASE}' BOOST_VERSION='${BOOST_VERSION}' ${TOOLS}/setup-debian-dev.sh "${rootfs}"
  COMMAND echo "========================================================="
  COMMAND echo "-- executing ${rootfs}/post-install ---"  
  COMMAND ${SUDO} chroot ${rootfs} /bin/bash -c ./post-install.sh
  COMMAND echo "========================================================="
  COMMAND echo "-- image mount on ${bootfs}, ${rootfs} -- You can now to install applications manually, then run make umount --"
  DEPENDS ${ROOTFS} ${UBOOT} ${BOOT_FILES} ${PACKAGES}
  USES_TERMINAL
  COMMENT "-- making ${IMGFILE} --"  
  )

#add_custom_target( img  DEPENDS ${IMGFILE}  VERBATIM )

add_custom_target( umount
  COMMAND ${SUDO} ${TOOLS}/umount-all.sh ${bootfs} ${rootfs}
  COMMAND ${SUDO} ${TOOLS}/detach-all.sh
  COMMENT "-- umounting ${bootfs} ${rootfs} --"
  )
