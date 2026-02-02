# ExperienceCo Kiosk Fleet Configuration

This repository contains the NixOS configuration for managing a fleet of kiosk machines that boot directly to https://login.experienceco.com in Chrome kiosk mode.

## Features

- ✅ Immutable OS with atomic updates
- ✅ Centralized configuration management via Git
- ✅ Chrome kiosk mode pointing to https://login.experienceco.com
- ✅ Full webcam and microphone support (auto-granted permissions)
- ✅ Automatic daily updates from this repository
- ✅ Easy rollback to previous configurations
- ✅ Screen blanking disabled
- ✅ Minimal attack surface
- ✅ Remote SSH management

## Repository Structure

```
kiosk-fleet/
├── flake.nix                    # Main flake configuration defining all kiosks
├── flake.lock                   # Locked dependency versions (auto-generated)
├── kiosk-common.nix            # Shared configuration for all kiosks
├── hardware-configuration.nix   # Hardware config template
├── README.md                    # This file
├── QUICKSTART.md               # Fast deployment guide
├── TROUBLESHOOTING.md          # Problem-solving checklist
├── ADVANCED_EXAMPLES.md        # Location-specific configurations
├── WEBCAM_SUPPORT.md           # Webcam and microphone setup
└── MICROSD_SETUP.md            # MicroSD card optimization guide
```

## Hardware Requirements

- **Storage:** 32GB minimum (64GB recommended)
  - Works great with microSD cards - see MICROSD_SETUP.md
  - Optimized for flash storage longevity
- **RAM:** 2GB minimum (4GB recommended)
- **Network:** Ethernet or WiFi
- **Display:** Any HDMI/DisplayPort monitor
- **Optional:** USB webcam for video conferencing

## Initial Setup

### 1. Prepare This Repository

```bash
# Clone this repo (or fork it to your organization)
git clone https://github.com/YOUR_USERNAME/kiosk-fleet.git
cd kiosk-fleet

# Update the autoUpgrade.flake URL in kiosk-common.nix
# Change: flake = "github:YOUR_USERNAME/kiosk-fleet";
# To your actual GitHub username/organization

# Commit and push
git add .
git commit -m "Initial configuration"
git push
```

### 2. Install NixOS on Your First Kiosk

Download NixOS minimal ISO from https://nixos.org/download.html

Boot from USB and follow these steps:

```bash
# Partition the disk (example for /dev/sda)
sudo parted /dev/sda -- mklabel gpt
sudo parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/sda -- set 1 esp on
sudo parted /dev/sda -- mkpart primary 512MiB 100%

# Format partitions
sudo mkfs.fat -F 32 -n boot /dev/sda1
sudo mkfs.ext4 -L nixos /dev/sda2

# Mount filesystems
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot

# Generate initial config
sudo nixos-generate-config --root /mnt

# Copy the generated hardware config
sudo cp /mnt/etc/nixos/hardware-configuration.nix /tmp/

# Clone your flake repo
cd /mnt/etc/nixos
sudo rm -rf *
sudo git clone https://github.com/YOUR_USERNAME/kiosk-fleet.git .

# Replace template hardware config with the generated one
sudo cp /tmp/hardware-configuration.nix .

# Install NixOS
sudo nixos-install --flake .#kiosk-01

# Set root password when prompted
# Reboot
sudo reboot
```

### 3. Post-Installation Setup

After rebooting into your new kiosk:

```bash
# Log in as root (or kiosk user if you set a password)

# Enable and start NetworkManager
sudo systemctl start NetworkManager
sudo nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD"

# Test that Chrome launches correctly
# The kiosk should auto-login and launch Chrome in kiosk mode
```

### 4. Deploy to Additional Kiosks

For each additional kiosk:

1. Install NixOS using the same steps as above
2. Change the hostname in the install command:
   ```bash
   sudo nixos-install --flake .#kiosk-02  # or kiosk-03, etc.
   ```
3. Each kiosk will automatically register and pull updates from your repo

## Adding More Kiosks

To add a new kiosk to the fleet, edit `flake.nix`:

```nix
kiosk-04 = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./hardware-configuration.nix
    ./kiosk-common.nix
    {
      networking.hostName = "kiosk-04";
    }
  ];
};
```

Commit and push:
```bash
git add flake.nix
git commit -m "Add kiosk-04"
git push
```

## Making Changes

### Change the Homepage URL

Edit `kiosk-common.nix` and update the URL in the Chrome launch command:

```nix
"https://login.experienceco.com" &
```

Change to your new URL, commit, and push:

```bash
git add kiosk-common.nix
git commit -m "Update homepage URL"
git push
```

All kiosks will automatically pull and apply this change during their next scheduled update (4 AM daily).

### Force Immediate Update on a Kiosk

SSH into the kiosk and run:

```bash
sudo nixos-rebuild switch --flake github:YOUR_USERNAME/kiosk-fleet#kiosk-01 --refresh
```

### Change Update Schedule

In `kiosk-common.nix`, modify:

```nix
system.autoUpgrade = {
  dates = "04:00";  # Change this (uses systemd timer format)
};
```

Examples:
- `"hourly"` - Every hour
- `"daily"` - Every day at midnight
- `"04:00"` - Every day at 4 AM
- `"Mon,Wed,Fri 02:00"` - Monday, Wednesday, Friday at 2 AM

### Add New Packages

Edit `kiosk-common.nix`:

```nix
environment.systemPackages = with pkgs; [
  google-chrome
  vim
  git
  # Add more packages here
  firefox
  htop
];
```

### Configure Different Kiosks Differently

Create machine-specific configs:

```nix
# In flake.nix
kiosk-warehouse = nixpkgs.lib.nixosSystem {
  modules = [
    ./kiosk-common.nix
    {
      networking.hostName = "kiosk-warehouse";
      # Override the Chrome URL for this specific kiosk
      system.activationScripts.kioskOpenboxConfig = pkgs.lib.mkForce ''
        # Custom config with different URL
        # ...
      '';
    }
  ];
};
```

## Rollback

If an update causes issues:

### On a Single Kiosk

```bash
# List available generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or rollback to specific generation
sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation 123
```

### Via Git

```bash
# Revert the problematic commit
git revert HEAD
git push

# Kiosks will update to the reverted config automatically
```

## Monitoring and Management

### Check Kiosk Status Remotely

```bash
# SSH into kiosk
ssh root@kiosk-01.local  # or use IP address

# Check system status
systemctl status display-manager
systemctl status chrome-kiosk

# View logs
journalctl -u display-manager -f
journalctl -u chrome-kiosk -f

# Check last update
nixos-rebuild list-generations
```

### Enable SSH Key Authentication

For security, add your SSH key to `kiosk-common.nix`:

```nix
users.users.root.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your-email@example.com"
];
```

## Troubleshooting

### Chrome Won't Launch

```bash
# Check if X server is running
ps aux | grep X

# Check openbox logs
cat /home/kiosk/.xsession-errors

# Manually test Chrome
su - kiosk
DISPLAY=:0 google-chrome-stable --kiosk "https://login.experienceco.com"
```

### Network Issues

```bash
# Check network status
nmcli device status
nmcli connection show

# Restart NetworkManager
sudo systemctl restart NetworkManager
```

### Updates Not Applying

```bash
# Check auto-upgrade status
sudo systemctl status nixos-upgrade.service

# View upgrade logs
sudo journalctl -u nixos-upgrade.service

# Manually trigger update
sudo systemctl start nixos-upgrade.service
```

### Disk Space Issues

```bash
# Check disk usage
df -h

# Run garbage collection
sudo nix-collect-garbage --delete-older-than 7d

# More aggressive cleanup
sudo nix-collect-garbage -d
```

## Security Recommendations

1. **Use SSH keys only** - Disable password authentication
2. **Keep flake.lock updated** - Run `nix flake update` periodically
3. **Enable automatic reboots** - Set `allowReboot = true` in autoUpgrade
4. **Monitor access logs** - Check `/var/log/auth.log` regularly
5. **Use a firewall** - Only expose necessary ports (22 for SSH)

## Advanced Configuration

### Add Multiple Displays

Edit `kiosk-common.nix`:

```nix
services.xserver.xrandrHeads = [
  { output = "HDMI-1"; primary = true; }
  { output = "HDMI-2"; monitorConfig = ''
    Option "RightOf" "HDMI-1"
  ''; }
];
```

### Enable Remote Desktop (VNC)

Add to `kiosk-common.nix`:

```nix
services.x11vnc = {
  enable = true;
  settings.display = ":0";
};
```

### Add Watchdog for Auto-Recovery

Already configured in `kiosk-common.nix`:

```nix
systemd.watchdog = {
  runtimeTime = "30s";
  rebootTime = "10min";
};
```

## Support

For issues specific to:
- **NixOS**: https://nixos.org/manual/nixos/stable/
- **Flakes**: https://nixos.wiki/wiki/Flakes
- **This configuration**: Open an issue in this repository

## License

MIT License - Modify and use as needed for your organization.
