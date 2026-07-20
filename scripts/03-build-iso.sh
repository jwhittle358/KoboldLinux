#!/bin/sh
set -eu
: "${ALPINE_BRANCH:=edge}"
: "${ALPINE_ARCH:=x86_64}"
: "${ALPINE_REPO_MAIN:=https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/main}"
: "${ALPINE_REPO_COMMUNITY:=https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/community}"
export TMPDIR="${TMPDIR:-$HOME/tmp}"
mkdir -p "$TMPDIR" "$HOME/iso"
sh "$HOME/aports/scripts/mkimage.sh" \
  --tag "$ALPINE_BRANCH" \
  --outdir "$HOME/iso" \
  --arch "$ALPINE_ARCH" \
  --repository "$ALPINE_REPO_MAIN" \
  --repository "$ALPINE_REPO_COMMUNITY" \
  --profile kobold_linux
