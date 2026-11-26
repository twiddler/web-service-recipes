#!/usr/bin/env bash

set -e pipefail

# The live ISO resolves Nixpkgs through `flake:nixpkgs`.
sudo nixos-install --option extra-experimental-features 'nix-command flakes'
