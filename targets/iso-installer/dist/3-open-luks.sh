#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  echo "Usage: ${0##*/} /dev/DISK" >&2
  exit 1
}

partitions=$(lsblk -ln \
  --filter 'TYPE == "part" && FSTYPE == "crypto_LUKS"' \
  -o PATH,SIZE -- "$1")

[[ -n "$partitions" ]] || {
  echo "No LUKS partitions found on $1." >&2
  exit 1
}

mapfile -t options <<< "$partitions"

PS3="Select the new root partition: "

select partition in "${options[@]}"; do
  [[ -n "$partition" ]] || continue

  sudo cryptsetup open "${partition%% *}" nixos-root
  break
done
