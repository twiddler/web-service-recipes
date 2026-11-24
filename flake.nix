{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      stateVersion = "26.05";
      example = "http";
    in
    {
      nixosConfigurations =
        let
          exampleModule = name: ./examples/${example}/configuration.nix;
        in
        {
          "${example}/local-vm" = nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
              (exampleModule example)
              { system.stateVersion = stateVersion; }
            ];
          };

          "${example}/iso-installer" = nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
              (import ./targets/iso-installer/installer.nix {
                inherit stateVersion;
                exampleModule = exampleModule example;
              })
            ];
          };
        };
    };
}
