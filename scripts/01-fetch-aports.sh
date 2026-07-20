#!/bin/sh
set -eu
# mkimage sets $tmp before invoking this helper.
makefile root:root 0644 "$tmp/etc/apk/world" <<'WORLD'
alpine-base
openssh
sudo
doas
bash
curl
jq
git
vim
rsync
nftables
tcpdump
nmap
bind-tools
iproute2
iputils
chrony
ca-certificates
openssl
util-linux
e2fsprogs
dosfstools
WORLD
mkdir -p "$tmp/etc"
mkdir -p "$tmp/etc/skel/.config
cp -rf ../.config/* "$tmp/etc/skel/.config/"
cat > "$tmp/etc/motd" <<'MOTD'
Kobold Linux
Custom lightweight live environment for infrastructure and security administration.
MOTD
rc_add networking boot
rc_add sshd default
rc_add chronyd default
