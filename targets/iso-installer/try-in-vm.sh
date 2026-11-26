#!/usr/bin/env nix
#! nix shell nixpkgs#bash nixpkgs#qemu nixpkgs#coreutils --command bash

set -euo pipefail

script_dir=$(dirname -- "$0")
shopt -s nullglob
isos=("$script_dir"/result/iso/*.iso)
if (( ${#isos[@]} != 1 )) || [[ ! -f ${isos[0]} ]]; then
  echo "Expected exactly one ISO in $script_dir/result/iso. Run $script_dir/build.sh first." >&2
  exit 1
fi

vm="${XDG_STATE_HOME:-$HOME/.local/state}/deploy/iso-vm"
disk="$vm/disk.qcow2"
vars="$vm/vars.fd"
firmware="$(dirname "$(realpath "$(command -v qemu-system-x86_64)")")/../share/qemu"

mkdir -p "$vm"

[[ -e $disk ]] || qemu-img create -f qcow2 "$disk" 40G
[[ -e $vars ]] || install -m600 "$firmware/edk2-i386-vars.fd" "$vars"

exec qemu-system-x86_64 \
  -machine q35,accel=kvm:tcg \
  -m 4096 -smp 4 \
  -drive if=pflash,format=raw,readonly=on,file="$firmware/edk2-x86_64-code.fd" \
  -drive if=pflash,format=raw,file="$vars" \
  -drive if=virtio,format=qcow2,file="$disk" \
  -cdrom "${isos[0]}" \
  -boot order=cd,menu=on \
  -nic user,model=virtio-net-pci \
  -display gtk
