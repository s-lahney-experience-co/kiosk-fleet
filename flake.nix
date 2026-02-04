{
  description = "ExperienceCo Kiosk Fleet Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      # Example kiosk configurations - add more as needed
      kiosk-01 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ./kiosk-common.nix
          {
            networking.hostName = "kiosk-01";
          }
        ];
      };

      kiosk-02 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ./kiosk-common.nix
          {
            networking.hostName = "kiosk-02";
          }
        ];
      };

      kiosk-03 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ./kiosk-common.nix
          {
            networking.hostName = "kiosk-03";
          }
        ];
      };
    };
  };
}
