{ stateVersion, exampleModule }:

{
  image.modules.iso-installer-minimal =
    { modulesPath, ... }:
    {
      imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

      isoImage.contents = [
        {
          source = ./dist;
          target = "/dist";
        }
      ];

      environment.etc = {
        # The live installer provides these files for copying to /mnt/etc/nixos.
        "nixos/configuration.nix".text = ''
          {
            imports = [
              ./hardware-configuration.nix
              ./example.nix
            ];

            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            networking.networkmanager.enable = true;

            system.stateVersion = ${builtins.toJSON stateVersion};
          }
        '';
        "nixos/example.nix".source = exampleModule;
      };
    };
}
