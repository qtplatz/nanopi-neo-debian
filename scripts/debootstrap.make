#!Makefile

DISTRO    = 
TARGETDIR = ../arm-linux-gnueabihf-rootfs-${DISTRO}

all:
	@echo "-- run 'make world' to build debian rootfs"

world:
	targetdir=${TARGETDIR} distro=${DISTRO} ./debootstrap.sh

clean:
	sudo rm -rf ${TARGETDIR}

