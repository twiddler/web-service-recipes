#!/usr/bin/env bash

set -eu

cd "$(dirname "$0")"

nixos-rebuild build-vm --flake "../../#http/local-vm"
