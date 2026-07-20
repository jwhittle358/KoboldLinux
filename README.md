#!/bin/sh
set -eu
apk add abuild alpine-conf syslinux xorriso squashfs-tools grub mtools git qemu-system-x86_64
abuild-keygen -a -i
