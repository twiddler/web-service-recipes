I want to have a NixOS installation medium that

1. installs NixOS and
2. installs my custom configuration at the same time.

The default GUI installer (Calamares) does not support installing a custom NixOS configuration, so I have to use other tools.

This is a guide and a collection of helper scripts to do that.

# Prerequisites

This guide requires

- a UEFI machine with
- a single disk that uses
- GPT partitioning.

# Installing with systemd-repart

1. If you want to dual-boot Windows on the same disk, (install Windows first, then) shrink the Windows volume in Windows Disk Management and leave the freed space unallocated.
2. Create your own NixOS .iso:

   ```console
   $ ./build.sh
   ```

   The custom .iso includes the NixOS configuration and helper scripts for installing it.

3. Flash the .iso onto a USB drive:

   ```console
   $ ./burn.sh
   ```

   Burning erases the selected USB drive.

   The installer bundles the selected example and uses the nixpkgs revision from the ISO build.

   (Instead of burning the ISO to a USB drive and performing the remaining steps on a real machine, you can also try this in a virtual machine by running `$ ./build.sh && ./try-in-vm.sh`.)

4. Boot from the USB drive.

   If you need a German keyboard layout:

   ```console
   $ /iso/dist/0-configure-keyboard.sh
   ```

5. Create the LUKS key file:

   ```console
   $ /iso/dist/1-create-luks-key.sh
   ```

6. If you want to dual-boot Windows, reuse the existing ESP partition without formatting or resizing it. You will effectively have to do something like this:

   ```console
   $ rm /iso/dist/repart.d/0-esp.conf
   ```

   This will fail because `/iso/dist/` is in a read-only file system. You must copy all but `0-esp.conf` somewhere else and point to that directory.

7. Create and format partitions:

   ```console
   $ /iso/dist/2-repart.sh
   ```

8. Open the new LUKS root partition. Replace `/dev/nvme0n1` with the disk you just partitioned:

   ```console
   $ /iso/dist/3-open-luks.sh /dev/nvme0n1
   ```

   (If more than one partition is listed, use the output from step 7 to identify the new one.)

   The unlocked device is `/dev/mapper/nixos-root`.

9. Mount the unlocked root and the EFI System Partition (ESP):

   ```console
   $ /iso/dist/4-mount-fs-for-installing.sh
   ```

   (If several ESPs are listed, use the device path to identify the right one)

10. Verify that both `/mnt` and `/mnt/boot` are listed:

    ```console
    $ /iso/dist/5-verify-mounts.sh
    ```

    (During installation, `/mnt` represents the root of your future operating system.)

11. Copy the bundled configuration to the target and generate its hardware configuration:

    ```console
    $ /iso/dist/6-prepare-nixos-config.sh
    ```

12. The installer needs internet to download packages. If you're not already online (for example, over Ethernet), connect to Wi-Fi:

    ```console
    $ /iso/dist/7-connect-to-wifi.sh
    ```

13. Install NixOS:

    ```console
    $ /iso/dist/8-install-nixos.sh
    ```

14. Reboot:

    ```console
    $ sudo reboot now
    ```

# Installing with disko

[disko](https://github.com/nix-community/disko) is an alternative to systemd-repart. It

- partitions drives,
- formats partitions,
- mounts filesystems

declaratively.

However, disko does not support dual-booting:

> Dual booting with other operating systems is not supported. -- https://github.com/nix-community/disko/blob/master/docs/quickstart.md?utm_source=chatgpt.com

Since I currently also have Windows on my machines, I have not tried disko yet.

## config

This might be a good config. I have not tried it yet. I only leave this here as a starting point in case I do want to try disko in the future.

```nix
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1"; # This is specific to the host. Replace this with a stable device identifier as described below.

    content = {
      type = "gpt";

      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };

        root = {
          size = "100%";
          content = {
          type = "luks";
          name = "crypted";

          askPassword = true;

          settings = {
            allowDiscards = true; # "Allow using of discards (TRIM) […] may lead to the leak of information about the ciphertext device (filesystem type, used space etc.)", "disk lifetime would increase" -- https://askubuntu.com/a/243527
            bypassWorkqueues = true; # "Enabling this should improve performance on SSDs" -- https://mynixos.com/nixpkgs/option/boot.initrd.luks.devices.%3Cname%3E.bypassWorkqueues
          };

          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
```

Replace `/dev/nvme0n1` with a stable device identifier. You can determine a stable identifier with

```console
$ ls -d /dev/disk/by-id/*uuid* | grep -vE -- '-part[0-9]+$' | xargs -r -I{} sh -c 'echo "$1 -> $(readlink -f "$1")"' _ {}
```

```bash
# run disko, then …
$ nixos-generate-config
$ nixos-install
```
