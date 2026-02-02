# Example: Location-Specific Kiosk Configurations

If you need different kiosks to point to different URLs or have different settings,
here's how to customize them while still using the common base configuration.

## Option 1: Different URLs per Location

Create location-specific configuration files:

### locations/warehouse.nix
```nix
{ config, pkgs, ... }:
{
  # Import common config
  imports = [ ../kiosk-common.nix ];

  # Override the Chrome kiosk URL
  system.activationScripts.kioskOpenboxConfig = pkgs.lib.mkForce ''
    mkdir -p /home/kiosk/.config/openbox
    cat > /home/kiosk/.config/openbox/autostart << 'EOF'
xset s off
xset -dpms
xset s noblank
unclutter -idle 5 &
google-chrome-stable \
  --kiosk \
  --no-first-run \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --noerrdialogs \
  "https://warehouse.experienceco.com" &
EOF
    chown -R kiosk:users /home/kiosk/.config
  '';
}
```

### locations/lobby.nix
```nix
{ config, pkgs, ... }:
{
  imports = [ ../kiosk-common.nix ];

  system.activationScripts.kioskOpenboxConfig = pkgs.lib.mkForce ''
    mkdir -p /home/kiosk/.config/openbox
    cat > /home/kiosk/.config/openbox/autostart << 'EOF'
xset s off
xset -dpms
xset s noblank
unclutter -idle 5 &
google-chrome-stable \
  --kiosk \
  --no-first-run \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --noerrdialogs \
  "https://lobby.experienceco.com" &
EOF
    chown -R kiosk:users /home/kiosk/.config
  '';
}
```

Then update your flake.nix:

```nix
{
  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      warehouse-kiosk-01 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ./locations/warehouse.nix
          { networking.hostName = "warehouse-kiosk-01"; }
        ];
      };

      lobby-kiosk-01 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ./locations/lobby.nix
          { networking.hostName = "lobby-kiosk-01"; }
        ];
      };
    };
  };
}
```

## Option 2: URL as Parameter

Create a reusable module that takes the URL as a parameter:

### kiosk-module.nix
```nix
{ config, pkgs, lib, kioskUrl, ... }:
{
  imports = [ ./kiosk-common.nix ];

  system.activationScripts.kioskOpenboxConfig = pkgs.lib.mkForce ''
    mkdir -p /home/kiosk/.config/openbox
    cat > /home/kiosk/.config/openbox/autostart << 'EOF'
xset s off
xset -dpms
xset s noblank
unclutter -idle 5 &
google-chrome-stable \
  --kiosk \
  --no-first-run \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --noerrdialogs \
  "${kioskUrl}" &
EOF
    chown -R kiosk:users /home/kiosk/.config
  '';
}
```

Then in flake.nix:

```nix
{
  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      warehouse-01 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { kioskUrl = "https://warehouse.experienceco.com"; };
        modules = [
          ./hardware-configuration.nix
          ./kiosk-module.nix
          { networking.hostName = "warehouse-01"; }
        ];
      };

      lobby-01 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { kioskUrl = "https://lobby.experienceco.com"; };
        modules = [
          ./hardware-configuration.nix
          ./kiosk-module.nix
          { networking.hostName = "lobby-01"; }
        ];
      };
    };
  };
}
```

## Option 3: Different Time Zones

```nix
# In flake.nix
east-coast-kiosk = nixpkgs.lib.nixosSystem {
  modules = [
    ./kiosk-common.nix
    {
      networking.hostName = "east-coast-kiosk";
      time.timeZone = "America/New_York";
    }
  ];
};

west-coast-kiosk = nixpkgs.lib.nixosSystem {
  modules = [
    ./kiosk-common.nix
    {
      networking.hostName = "west-coast-kiosk";
      time.timeZone = "America/Los_Angeles";
    }
  ];
};
```

## Option 4: Different Update Schedules

```nix
# Critical kiosks - update less frequently
production-kiosk = nixpkgs.lib.nixosSystem {
  modules = [
    ./kiosk-common.nix
    {
      networking.hostName = "production-kiosk";
      system.autoUpgrade.dates = "Sun 03:00"; # Only on Sundays
    }
  ];
};

# Test kiosks - update immediately
test-kiosk = nixpkgs.lib.nixosSystem {
  modules = [
    ./kiosk-common.nix
    {
      networking.hostName = "test-kiosk";
      system.autoUpgrade.dates = "hourly"; # Check every hour
    }
  ];
};
```

## Benefits of This Approach

1. **DRY (Don't Repeat Yourself)**: Common configuration stays in kiosk-common.nix
2. **Easy to maintain**: Changes to common settings propagate to all kiosks
3. **Flexible**: Each kiosk can override specific settings
4. **Type-safe**: Nix will catch configuration errors before deployment
5. **Version controlled**: All changes tracked in Git

Choose the approach that best fits your organizational structure and needs!
