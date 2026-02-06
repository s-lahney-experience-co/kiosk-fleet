{
  description = "ExperienceCo Kiosk Fleet Configuration";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
    let
      # Generate configs for kiosks 001-100
      mkKiosk = num: {
        name = "exp-stream-${num}";
        value = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./kiosk-common.nix
            {
              networking.hostName = "exp-stream-${num}";
            }
          ];
        };
      };
      
      # Generate list of kiosk numbers with leading zeros (001-100)
      kioskNumbers = map (n: 
        if n < 10 then "00${toString n}" 
        else if n < 100 then "0${toString n}"
        else toString n
      ) (nixpkgs.lib.range 1 100);
      
    in {
      nixosConfigurations = builtins.listToAttrs (map mkKiosk kioskNumbers);
    };
}