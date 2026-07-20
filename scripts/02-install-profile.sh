#!/bin/sh
set -eu
install -m 0755 profiles/mkimg.kobold_linux.sh "$HOME/aports/scripts/mkimg.kobold_linux.sh"
install -m 0755 profiles/genapkovl-kobold_linux.sh "$HOME/aports/scripts/genapkovl-kobold_linux.sh"
