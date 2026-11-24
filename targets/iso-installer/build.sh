#!/usr/bin/env bash

set -eu

cd "$(dirname "$0")"

nixos-rebuild build-image --image-variant iso-installer-minimal --flake "../../#http/iso-installer"
