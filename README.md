=====
Nanopi-neo debian SD Card image generator
=====

This project contains cmake and dependent bash scripts for nanopi-neo debian boot SD-Card.

===============
 Prerequisite
===============

1. Linux (debian9) host (x86_64).
2. Multiarch for armhf enabled on host.

===========================
 Dependent debian packages 
===========================

sudo dpkg --add-architecture armhf
sudo apt-get -y install crossbuild-essential-armhf
sudo apt-get -y install bc build-essential cmake dkms git libncurses5-dev
(May be some else...)

===========================
 Procedure
===========================

Run './bootstrap.sh' on project root directory.
Then, chdir to "../build-armhf/nanopi-neo.release/", and type make

It will make 'nanopi-neo_streatch-<version_number>-dev.img'

Try 'make help' on build directory ("../build-armhf/nanopi-neo.release/") for more information.

Good luck.



