# Quick Start Guide

This is a condensed version of the setup process for rapid deployment.

## Prerequisites

- NixOS minimal ISO on a USB drive
- GitHub account
- Small computer with UEFI boot support

## Step 1: Prepare Repository (5 minutes)

```bash
# Fork or clone this repo to your GitHub account
# Update kiosk-common.nix line 30:
flake = "github:s-lahney-experience-co/kiosk-fleet";

# Commit and push
git add .
git commit -m "Configure for my organization"
git push
```

## Step 2: Install First Kiosk (15 minutes)

```bash
# Boot from NixOS USB
# Get root shell
sudo su

# Quick disk setup (ADJUST /dev/sda to your disk!)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB 100%
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2

# Mount
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Get config
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix /tmp/
cd /mnt/etc/nixos
rm -rf *
git clone https://github.com/YOUR_USERNAME/kiosk-fleet.git .
cp /tmp/hardware-configuration.nix .

# Install
nixos-install --flake .#kiosk-01

# Set root password when prompted
# Reboot
reboot
```

## Step 3: Configure Network (2 minutes)

```bash
# After reboot, login as root
# Connect to WiFi (if needed)
nmcli device wifi connect "SSID" password "PASSWORD"

# Or for Ethernet, it should work automatically
```

## Step 4: Verify (1 minute)

The kiosk should:
1. Auto-login as the kiosk user
2. Launch Chrome in fullscreen kiosk mode
3. Display https://login.experienceco.com

## Deploy Additional Kiosks

Repeat Step 2, changing only the hostname:
- `nixos-install --flake .#kiosk-02`
- `nixos-install --flake .#kiosk-03`
- etc.

## Making Changes

```bash
# Edit kiosk-common.nix locally
# Commit and push
git add kiosk-common.nix
git commit -m "Update configuration"
git push

# All kiosks auto-update at 4 AM daily
# Or force immediate update on a kiosk:
ssh root@kiosk-01
nixos-rebuild switch --flake github:YOUR_USERNAME/kiosk-fleet#kiosk-01 --refresh
```

## Common Issues

**Chrome won't launch**: Check `/home/kiosk/.xsession-errors`
**Network fails**: Run `nmcli device status` and `systemctl status NetworkManager`
**Updates not applying**: Check `systemctl status nixos-upgrade.service`

## Emergency Rollback

```bash
# On the kiosk
nixos-rebuild switch --rollback
```

That's it! You now have a centrally managed, immutable kiosk fleet.
