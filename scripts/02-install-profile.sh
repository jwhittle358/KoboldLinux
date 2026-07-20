#!/bin/sh
set -eu
install -m 0755 profiles/mkimg.secops.sh "$HOME/aports/scripts/mkimg.secops.sh"
install -m 0755 profiles/genapkovl-secops.sh "$HOME/aports/scripts/genapkovl-secops.sh"
