#!/usr/bin/env bash

set -euo pipefail

definitions="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/repart.d"

disks=$(lsblk -J -T -o PATH,TYPE,SIZE,MODEL,RO,MOUNTPOINTS | jq -r '
  .blockdevices[]
  | select(.type == "disk" and .ro == false)
  | select(all(recurse(.children[]?) | .mountpoints[]?; . == null or . == ""))
  | select(all(.children[]? | recurse(.children[]?); .type == "part"))
  | "\(.path)  \(.size)  \(.model // "(unknown)")"
')

if [[ -z "$disks" ]]; then
  echo "No eligible disks found." >&2
  exit 1
fi

echo "Available disks:" >&2
echo "$disks" >&2

read -rp "Enter device: " device
device="/dev/${device#/dev/}"

repart() {
  sudo systemd-repart --no-pager --empty=allow --definitions="$definitions" --dry-run="$1" -- "$device"
}

repart yes

echo "WARNING: Applying these changes may cause data loss." >&2
read -rp "Type '$device' to apply: " answer
[[ "$answer" == "$device" ]] || exit 1

repart no
