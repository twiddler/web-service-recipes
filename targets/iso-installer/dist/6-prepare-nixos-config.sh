#!/usr/bin/env bash

set -euo pipefail

sudo install -Dm644 -t /mnt/etc/nixos /etc/nixos/*.nix
sudo nixos-generate-config --root /mnt --show-hardware-config | sudo tee /mnt/etc/nixos/hardware-configuration.nix >/dev/null
