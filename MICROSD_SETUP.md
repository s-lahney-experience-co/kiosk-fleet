# MicroSD Card Setup Guide

## Storage Requirements

### Recommended Sizes

| Size | Use Case | Notes |
|------|----------|-------|
| **16 GB** | Absolute minimum | Requires aggressive cleanup, risky |
| **32 GB** | Recommended minimum | Good for most kiosks, 3-5 rollback generations |
| **64 GB** | Ideal | Plenty of space, 10+ generations, room for growth |
| **128 GB+** | Overkill | Only needed for special requirements |

### Why 32GB is the Sweet Spot

**Storage Breakdown for 32GB:**
```
Total: 32 GB
├── Boot partition: 512 MB
├── Base NixOS: 5-6 GB
├── 5 system generations: 10-12 GB (for rollback)
├── Chrome cache: 500 MB
├── Logs: 500 MB
└── Free space: 12-14 GB (buffer for updates)
```

## MicroSD Card Selection

### Recommended Specifications

**Class/Speed:**
- Minimum: Class 10 / UHS-I (U1)
- Recommended: UHS-I (U3) or better
- Ideal: A1 or A2 rated (optimized for random I/O)

**Brands (in order of reliability):**
1. Samsung EVO/PRO series
2. SanDisk Extreme/Ultra
3. Kingston Canvas Go/React

**Example Good Choices:**
- Samsung EVO Plus 32GB (A2, U3) - ~$10
- SanDisk Extreme 32GB (A2, V30) - ~$12
- Kingston Canvas React Plus 32GB (A2, V90) - ~$15

### ⚠️ Avoid:
- No-name brands
- Cards without speed ratings
- Ultra-cheap cards (likely fake or low quality)
- Cards over 128GB (diminishing returns, higher failure rate)

## Installation for MicroSD Cards

### Special Considerations

MicroSD cards are slower than SSDs, so:
1. Expect slower boot times (30-60 seconds)
2. First boot and updates will take longer
3. Chrome may take 5-10 seconds to launch

### Optimized Partition Layout for MicroSD

```bash
# Use this partitioning scheme for better performance
parted /dev/mmcblk0 -- mklabel gpt

# Boot partition - 512MB is enough
parted /dev/mmcblk0 -- mkpart ESP fat32 1MiB 513MiB
parted /dev/mmcblk0 -- set 1 esp on

# Root partition - rest of card, with alignment
parted /dev/mmcblk0 -- mkpart primary ext4 513MiB 100%

# Format with optimized settings for flash storage
mkfs.fat -F 32 -n boot /dev/mmcblk0p1
mkfs.ext4 -L nixos -O ^has_journal -E lazy_itable_init=0,lazy_journal_init=0 /dev/mmcblk0p2
```

**Note:** Using `-O ^has_journal` disables journaling, which:
- ✅ Reduces writes (extends card life)
- ✅ Slightly faster
- ⚠️ Less safe if power is cut during writes

For more safety, keep journaling:
```bash
mkfs.ext4 -L nixos /dev/mmcblk0p2
```

### Mount with noatime

Add to your hardware-configuration.nix:

```nix
fileSystems."/" = {
  device = "/dev/disk/by-label/nixos";
  fsType = "ext4";
  options = [ "noatime" "nodiratime" ];  # Reduces write wear
};

fileSystems."/boot" = {
  device = "/dev/disk/by-label/boot";
  fsType = "vfat";
  options = [ "noatime" ];
};
```

## Storage Optimization for 32GB Cards

### Update kiosk-common.nix with Aggressive Cleanup

```nix
# More aggressive garbage collection for smaller cards
nix.gc = {
  automatic = true;
  dates = "daily";  # Run every day instead of weekly
  options = "--delete-older-than 14d";  # Keep only 2 weeks instead of 30 days
};

# Keep fewer boot generations
boot.loader.systemd-boot.configurationLimit = 5;  # Instead of 10+

# Limit journal size
services.journald.extraConfig = ''
  SystemMaxUse=100M
  SystemMaxFileSize=10M
'';

# Clear Chrome cache on reboot
systemd.tmpfiles.rules = [
  "D /home/kiosk/.cache/google-chrome 0755 kiosk users 0 -"
];
```

### For 16GB Cards (Emergency Only)

If you absolutely must use 16GB:

```nix
# EXTREME cleanup - use with caution
nix.gc = {
  automatic = true;
  dates = "daily";
  options = "--delete-older-than 7d";  # Keep only 1 week
};

# Keep only 2 generations (minimal rollback)
boot.loader.systemd-boot.configurationLimit = 2;

# Minimal journal
services.journald.extraConfig = ''
  SystemMaxUse=50M
  SystemMaxFileSize=5M
'';

# Disable Chrome cache entirely
systemd.user.services.chrome-kiosk = {
  serviceConfig = {
    ExecStart = pkgs.lib.mkForce ''
      ${pkgs.google-chrome}/bin/google-chrome-stable \
        --kiosk \
        --disk-cache-size=1 \
        --media-cache-size=1 \
        --disk-cache-dir=/tmp/chrome-cache \
        # ... other flags ...
    '';
  };
};
```

## Monitoring Storage Usage

### Check Space Regularly

```bash
# Overall usage
df -h

# NixOS store size
du -sh /nix/store

# Count system generations
nixos-rebuild list-generations | wc -l

# See what's using space
du -sh /nix/store/* | sort -h | tail -20

# Check journal size
journalctl --disk-usage
```

### Set Up Alerts

Add to kiosk-common.nix:

```nix
# Email alert when disk is 80% full (requires working mail setup)
systemd.timers.disk-check = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "daily";
    Persistent = true;
  };
};

systemd.services.disk-check = {
  script = ''
    USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $USAGE -gt 80 ]; then
      echo "Warning: Disk usage is $USAGE%" | logger -t disk-check
      # Add notification here if you have monitoring set up
    fi
  '';
};
```

## MicroSD Card Longevity

### Expected Lifespan

- **Consumer cards**: 1-3 years with daily updates
- **Industrial cards**: 5-10 years
- **Pro/High-endurance cards**: 3-5 years

### Extend Card Life

1. **Reduce write amplification:**
   - Use noatime mount option ✅ (already in config)
   - Disable journaling (optional, less safe)
   - Aggressive garbage collection ✅ (already in config)

2. **Use high-quality cards:**
   - Samsung PRO Endurance (rated for surveillance)
   - SanDisk MAX Endurance
   - Kingston High Endurance

3. **Monitor health:**
   ```bash
   # Check SMART data (if supported)
   smartctl -a /dev/mmcblk0
   ```

4. **Plan for replacement:**
   - Keep spare cards on hand
   - Document the reinstall process
   - Consider the card "consumable"

### Warning Signs of Failure

- System becomes read-only unexpectedly
- Slow boot times (slower than usual)
- Kernel errors in dmesg: `blk_update_request: I/O error`
- Files randomly corrupting
- Rebuild failures

**If you see these, replace the card immediately!**

## Quick Installation Script for MicroSD

```bash
#!/usr/bin/env bash
# Quick NixOS install script for microSD cards

set -e

DEVICE="/dev/mmcblk0"
HOSTNAME="kiosk-01"

echo "⚠️  This will ERASE $DEVICE completely!"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

# Partition
parted $DEVICE -- mklabel gpt
parted $DEVICE -- mkpart ESP fat32 1MiB 513MiB
parted $DEVICE -- set 1 esp on
parted $DEVICE -- mkpart primary ext4 513MiB 100%

# Format
mkfs.fat -F 32 -n boot ${DEVICE}p1
mkfs.ext4 -L nixos -O ^has_journal ${DEVICE}p2

# Mount
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Generate config
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix /tmp/

# Get flake
cd /mnt/etc/nixos
rm -rf *
git clone https://github.com/YOUR_USERNAME/kiosk-fleet.git .
cp /tmp/hardware-configuration.nix .

# Add noatime to hardware config
sed -i 's/options = \[ /options = [ "noatime" "nodiratime" /' hardware-configuration.nix

# Install
nixos-install --flake .#$HOSTNAME

echo "✅ Installation complete! Remove USB and reboot."
```

## Troubleshooting MicroSD Issues

### Card Not Detected

```bash
# Check if detected at all
lsblk
dmesg | grep mmc

# Reseat the card
# Try a USB card reader if internal reader fails
```

### Write Errors During Install

```bash
# Card might be write-protected (check physical switch)
# Or card might be fake/failing

# Test write speed
dd if=/dev/zero of=/mnt/test.img bs=1M count=1024
# Should be at least 10 MB/s for Class 10
```

### System Read-Only After Boot

```bash
# Card has likely failed or has errors
# Try remounting read-write
mount -o remount,rw /

# Check for errors
fsck.ext4 -f /dev/mmcblk0p2

# If errors persist, replace the card
```

## Cost Comparison

### Per Kiosk Storage Cost

| Size | Cost | Cost/Kiosk | Notes |
|------|------|------------|-------|
| 16GB | $5-8 | $6 | Not recommended |
| 32GB | $8-15 | $10 | Best value |
| 64GB | $12-20 | $15 | Extra headroom |

**For 10 kiosks:** 32GB costs $100 vs 64GB costs $150

**Recommendation:** Start with 32GB. If you hit storage issues, the problematic kiosks can be upgraded to 64GB individually.

## Summary

### Recommended Setup

- **Card size:** 32GB
- **Card type:** Samsung EVO Plus, SanDisk Extreme (A2 rated)
- **Filesystem:** ext4 with noatime
- **Cleanup:** Daily garbage collection, keep 5 generations
- **Expected life:** 2-3 years with daily updates

### When to Use 64GB

- Mission-critical kiosks (more rollback options)
- Difficult to service locations
- Want to avoid storage management
- Cost difference is negligible

### Avoid 16GB Unless

- Temporary/test deployment
- Budget is extremely tight
- You're comfortable with aggressive maintenance
- Risk of storage issues is acceptable
