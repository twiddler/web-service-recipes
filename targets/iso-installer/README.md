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

   The installer bundles the HTTP module and uses the Nixpkgs revision from the ISO build.

4. Boot from the USB drive.
5. Create the LUKS key file:

   ```console
   $ /dist/create-luks-key.sh
   ```

6. If you want to dual-boot Windows, reuse the existing ESP partition without formatting or resizing it:

   ```console
   $ rm /dist/repart.d/0-esp.conf
   ```

   (This might fail if that file is read-only; I have not tried this yet.)

7. Create and format partitions:

   ```console
   $ /dist/repart.sh
   ```

8. Find the newly created `crypto_LUKS` partition on the selected disk:

   ```console
   $ lsblk -o PATH,SIZE,FSTYPE,PARTUUID,MOUNTPOINTS
   ```

   Replace `ROOT_PARTUUID` with that partition's `PARTUUID`, then open the container:

   ```console
   $ sudo cryptsetup open /dev/disk/by-partuuid/ROOT_PARTUUID nixos-root
   ```

   The unlocked device is `/dev/mapper/nixos-root`.

9. Mount the unlocked root at `/mnt` and the ESP at `/mnt/boot`. Replace `ESP_PARTUUID` with the `PARTUUID` of the ESP:

   ```console
   $ sudo mount /dev/mapper/nixos-root /mnt

   $ sudo mkdir -p /mnt/boot
   $ lsblk -o PATH,SIZE,FSTYPE,PARTUUID,MOUNTPOINTS
   $ sudo mount /dev/disk/by-partuuid/ESP_PARTUUID /mnt/boot
   ```

   Verify both mounts before continuing.

   ```console
   $ findmnt -R /mnt
   ```

   (During installation, `/mnt` represents the root of your future operating system.)

10. Copy the bundled configuration to the target and generate its hardware configuration:

    ```console
    $ sudo install -Dm644 -t /mnt/etc/nixos /etc/nixos/*.nix
    $ sudo nixos-generate-config --root /mnt
    ```

11. The installer needs internet to download packages. Connect to the internet:

    ```console
    $ /dist/connect-to-internet.sh
    ```

12. Install NixOS:

    ```console
    $ nixos-install
    ```

    (`nixos-install` uses `/mnt` to map out the new installation.)

13. Reboot:

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
