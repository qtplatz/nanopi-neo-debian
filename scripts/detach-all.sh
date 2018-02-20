#!/bin/bash

count=`sudo losetup | grep "/dev/loop[0-9]" |wc -l`
echo $count " device(s) found"

while ((count)); do
    count=$((count-1))
    echo losetup -d /dev/loop$((count))
    sudo losetup -d /dev/loop$((count))
done
