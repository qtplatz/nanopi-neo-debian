#/bin/sh

if [ $# -ne 1 ]; then
    echo "$0 image.img"
    exit
fi

sudo losetup --show -f -P $1
