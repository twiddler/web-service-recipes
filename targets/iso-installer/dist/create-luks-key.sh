#!/usr/bin/env bash

set -e

IFS= read -r -s -p 'Enter LUKS passphrase: ' passphrase < /dev/tty
printf '\n' >&2

printf '%s' "$passphrase" | sudo sh -c 'umask 077; cat > /run/luks.key'
