# Quick Reference Card

## Essential Information

### Hardware Specs
- **Storage:** SanDisk MAX Endurance 64GB microSD
- **RAM:** 2GB minimum (4GB recommended)
- **Network:** WiFi or Ethernet
- **Display:** Any HDMI monitor
- **Optional:** USB webcam

### Key URLs
- **Kiosk Homepage:** https://login.experienceco.com
- **Your Config Repo:** github.com/s-lahney-experience-co/kiosk-fleet
- **NixOS Download:** https://nixos.org/download

### Important Files to Edit
1. `kiosk-common.nix` line 30 → Update YOUR_USERNAME
2. `hardware-configuration.nix` → Auto-generated during install

## Installation Commands (20 minutes)

```bash
# 1. Partition (adjust /dev/mmcblk0 for your device)
parted /dev/mmcblk0 -- mklabel gpt
parted /dev/mmcblk0 -- mkpart ESP fat32 1MiB 513MiB
parted /dev/mmcblk0 -- set 1 esp on
parted /dev/mmcblk0 -- mkpart primary ext4 513MiB 100%

# 2. Format
mkfs.fat -F 32 -n boot /dev/mmcblk0p1
mkfs.ext4 -L nixos /dev/mmcblk0p2

# 3. Mount
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# 4. Setup config
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix /tmp/
cd /mnt/etc/nixos
rm -rf *
git clone https://github.com/s-lahney-experience-co/kiosk-fleet.git .
cp /tmp/hardware-configuration.nix .

# 5. Install
nixos-install --flake .#kiosk-01

# 6. Set root password, then reboot
```

## Common Tasks

### Add New Kiosk
Edit `flake.nix`, add:
```nix
kiosk-04 = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./hardware-configuration.nix
    ./kiosk-common.nix
    { networking.hostName = "kiosk-04"; }
  ];
};
```

### Change Homepage URL
Edit `kiosk-common.nix` line ~75:
```nix
"https://login.experienceco.com" &
```

### Force Update Now
SSH into kiosk:
```bash
nixos-rebuild switch --flake github:YOUR_USERNAME/kiosk-fleet#kiosk-01 --refresh
```

### Rollback System
```bash
nixos-rebuild switch --rollback
```

### Check Disk Space
```bash
df -h
nix-collect-garbage -d  # Clean up
```

## Troubleshooting Quick Checks

### Kiosk Not Booting
- [ ] Is power connected?
- [ ] Is monitor on and connected?
- [ ] Check boot order in BIOS

### Chrome Not Launching
```bash
# Check logs
cat /home/kiosk/.xsession-errors

# Restart display manager
systemctl restart display-manager
```

### Webcam Not Working
```bash
# Check device
ls -l /dev/video*

# Check permissions
groups kiosk  # Should include: video, audio, camera
```

### Network Issues
```bash
# WiFi
nmcli device wifi connect "SSID" password "PASSWORD"

# Check status
ping google.com
```

### Out of Disk Space
```bash
# Aggressive cleanup
nix-collect-garbage -d
nixos-rebuild switch  # Rebuild to clean up
```

## Default Settings

- **Auto-login:** Yes (kiosk user)
- **Updates:** Daily at 4:00 AM
- **Garbage collection:** Daily
- **Generations kept:** 5
- **SSH port:** 22
- **Root password:** Set during installation
- **Kiosk password:** None (locked by default)

## File Locations

- **Config files:** `/etc/nixos/`
- **User home:** `/home/kiosk/`
- **NixOS store:** `/nix/store/`
- **Boot entries:** `/boot/loader/entries/`
- **Logs:** `/var/log/` or `journalctl`

## Remote Management

```bash
# SSH into kiosk
ssh root@kiosk-01.local

# View system status
systemctl status
journalctl -f  # Follow logs

# Check for updates
nixos-rebuild dry-build --flake github:YOUR_USERNAME/kiosk-fleet#kiosk-01
```

## Emergency Recovery

1. Boot from NixOS USB
2. Mount existing installation:
   ```bash
   mount /dev/disk/by-label/nixos /mnt
   mount /dev/disk/by-label/boot /mnt/boot
   nixos-enter --root /mnt
   ```
3. Fix issues or rollback
4. Reboot

## Need Help?

| Issue | See File |
|-------|----------|
| Installation | QUICKSTART.md |
| Webcam | WEBCAM_SUPPORT.md |
| MicroSD | MICROSD_SETUP.md |
| System errors | TROUBLESHOOTING.md |
| Custom configs | ADVANCED_EXAMPLES.md |
| Everything else | README.md |

## Update Schedule

- **Configuration changes:** Push to GitHub, kiosks auto-update at 4 AM
- **NixOS updates:** Included in daily auto-update
- **Chrome updates:** Included in daily auto-update
- **MicroSD replacement:** Every 5-7 years

---

**Keep this card handy during deployment!**

Print or save to your phone for quick reference.
