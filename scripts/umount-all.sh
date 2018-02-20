#!/bin/bash

for i in "$@"; do
	umount "$i"
done
exit 0 # ignore error code
