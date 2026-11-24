You can try this out on a virtual machine. You can run it with QEMU like so:

```console
$ ./build.sh
$ ./run.sh
```

QEMU maps port 8080 on the host to port 80 on the virtual machine (see `run.sh`).

In another terminal on the host, send an HTTP request to the virtual machine:

```console
$ curl localhost:8080
```

If you want to shutdown the machine, you cannot login and run `sudo shutdown now`, `systemctl poweroff` or whatever because the machine has no users. You can shut it down via QEMU:

- <kbd>Ctrl</kbd>+<kbd>A</kbd> then <kbd>x</kbd> to quit immediately, or
- <kbd>Ctrl</kbd>+<kbd>A</kbd> then <kbd>c</kbd> by `system_powerdown` to shutdown gracefully.

# Credits

- https://nix.dev/tutorials/nixos/nixos-configuration-on-vm.html
- https://gist.github.com/FlakM/0535b8aa7efec56906c5ab5e32580adf
