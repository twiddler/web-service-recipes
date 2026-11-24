#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

die() {
  echo "$*" >&2
  exit 1
}

cd "$(dirname "${BASH_SOURCE[0]}")"

# Find the ISO
isos=(result/iso/*.iso)

case ${#isos[@]} in
  0) die "Build not found. Run ./build.sh first." ;;
  1) iso="${isos[0]}" ;;
  *) die "Multiple ISOs found. Refusing to guess." ;;
esac

echo "Found $iso." >&2

# Find USB disks
disks=$(lsblk -J -d -o PATH,TYPE,TRAN,SIZE,MODEL,DISK-SEQ | jq '
  [.blockdevices[] | select(.type == "disk" and .tran == "usb" and .path != null)]
')

menu=$(jq -r '.[] | [.path, .size, .model] | join(" ")' <<< "$disks")
[[ -n "$menu" ]] || die "No USB disks found."

mapfile -t labels <<< "$menu"

# Select a disk
PS3="Which USB disk do you want to burn the ISO to? "
device=""

select label in "${labels[@]}"; do
  if [[ -n "$label" ]]; then
    device="${label%% *}"
    break
  fi
  echo "Invalid selection."
done >&2

[[ -n "$device" ]] || exit 1

sequence=$(jq -r --arg device "$device" '
  .[] | select(.path == $device) | .["disk-seq"] // empty
' <<< "$disks")

[[ "$sequence" =~ ^[0-9]+$ ]] || die "Missing disk sequence number."

# Validate the disk
[[ -b "$device" ]] &&
  [[ "$(lsblk -dnr -o TYPE,TRAN -- "$device")" == "disk usb" ]] ||
  die "Not a valid USB disk: $device"

iso_size=$(stat -Lc %s "$iso")
disk_size=$(lsblk -bdn -o SIZE -- "$device")

[[ "$disk_size" =~ ^[0-9]+$ ]] || die "Cannot determine disk size."
(( iso_size <= disk_size )) || die "ISO is too large for the disk."

# Confirm
lsblk -o PATH,SIZE,TYPE,MODEL,MOUNTPOINTS -- "$device" >&2

echo "Burning $(basename "$iso") to $device." >&2
echo "WARNING: All data on $device will be overwritten." >&2

read -rp "Type '$device' to proceed: " answer
[[ "$answer" == "$device" ]] || die "Cancelled."

# Perform final safety checks
mounts=$(lsblk -nr -o MOUNTPOINTS -- "$device")
[[ -z "${mounts//[[:space:]]/}" ]] || die "Unmount the disk first."

current_sequence=$(lsblk -dnr -o DISK-SEQ -- "$device")
[[ "$current_sequence" == "$sequence" ]] || die "The disk has changed."

# Burn
sudo dd if="$iso" of="$device" bs=4M status=progress conv=fdatasync,nocreat
