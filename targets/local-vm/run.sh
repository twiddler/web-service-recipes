#!/usr/bin/env bash

set -eu

cd "$(dirname "$0")"

QEMU_NET_OPTS="hostfwd=tcp::8080-:80" QEMU_KERNEL_PARAMS=console=ttyS0 ./result/bin/run-nixos-vm -nographic
