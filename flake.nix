{
  description = "ExperienceCo Kiosk Fleet Configuration";
  # Note: hardware-configuration.nix is generated per-kiosk during installation
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      # Example kiosk configurations - add more as needed
      exp-stream-001 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-001";
          }
        ];
      };

      exp-stream-002 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-002";
          }
        ];
      };

      exp-stream-003 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-003";
          }
        ];
      };
	  
      exp-stream-004 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-004";
          }
        ];
      };

      exp-stream-005 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-005";
          }
        ];
      };

      exp-stream-006 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-006";
          }
        ];
      };	  
	  
      exp-stream-007 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-007";
          }
        ];
      };

      exp-stream-008 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-008";
          }
        ];
      };

      exp-stream-009 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-009";
          }
        ];
      };
	  
      exp-stream-010 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-010";
          }
        ];
      };

      exp-stream-011 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-011";
          }
        ];
      };

      exp-stream-012 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-012";
          }
        ];
      };	  
	  
      exp-stream-013 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-013";
          }
        ];
      };

      exp-stream-014 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-014";
          }
        ];
      };

      exp-stream-015 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-015";
          }
        ];
      };
	  
      exp-stream-016 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-016";
          }
        ];
      };

      exp-stream-017 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-017";
          }
        ];
      };

      exp-stream-018 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-018";
          }
        ];
      };	  
	  
      exp-stream-019 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-019";
          }
        ];
      };

      exp-stream-020 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-020";
          }
        ];
      };

      exp-stream-021 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-021";
          }
        ];
      };
	  
      exp-stream-022 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-022";
          }
        ];
      };

      exp-stream-023 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-023";
          }
        ];
      };

      exp-stream-024 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-024";
          }
        ];
      };

      exp-stream-025 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kiosk-common.nix
          {
            networking.hostName = "exp-stream-025";
          }
        ];
      };	  
    };
  };
}
