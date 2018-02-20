###################### U-BOOT #########################

add_custom_command(
  OUTPUT ${UBOOT_BUILD_DIR}/Makefile
  COMMAND git clone git://git.denx.de/u-boot.git ${UBOOT_BUILD_DIR}
  )

add_custom_command( 
  OUTPUT ${UBOOT_BUILD_DIR}/u-boot-sunxi-with-spl.bin
  COMMAND ${MAKE} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- nanopi_neo_defconfig
  COMMAND ${MAKE} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
  DEPENDS ${UBOOT_BUILD_DIR}/Makefile
  WORKING_DIRECTORY ${UBOOT_BUILD_DIR}  
)

add_custom_target( u-boot DEPENDS ${UBOOT_BUILD_DIR}/u-boot-sunxi-with-spl.bin )

# Burn u-boot to SDCard, follow the procedure on  'http://linux-sunxi.org/Bootable_SD_card'

###################### end u-boot #######################
