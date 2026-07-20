#!/bin/sh
set -eu
: "${APORTS_GIT_URL:=https://gitlab.alpinelinux.org/alpine/aports.git}"
if [ -d "$HOME/aports/.git" ]; then
  git -C "$HOME/aports" pull --ff-only
else
  git clone --depth=1 "$APORTS_GIT_URL" "$HOME/aports"
fi
mkdir -p "$HOME/tmp" "$HOME/iso"
