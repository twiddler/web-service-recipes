#!/usr/bin/env bash

set -euo pipefail

EFI_SYSTEM_PARTITION_TYPE="c12a7328-f81f-11d2-ba4b-00a0c93ec93b"

partitions=$(lsblk -ln --filter "PARTTYPE == \"$EFI_SYSTEM_PARTITION_TYPE\"" -o PATH,SIZE)

[[ -n "$partitions" ]] || {
  echo "No EFI system partitions found." >&2
  exit 1
}

mapfile -t options <<< "$partitions"

PS3="Select the EFI system partition: "

select partition in "${options[@]}"; do
  [[ -n "$partition" ]] || continue

  sudo mount /dev/mapper/nixos-root /mnt
  sudo mkdir -p /mnt/boot
  sudo mount -o fmask=0077,dmask=0077 "${partition%% *}" /mnt/boot
  break
done
