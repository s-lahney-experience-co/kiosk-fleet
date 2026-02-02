# Troubleshooting Checklist

Use this checklist to diagnose common issues with your kiosk fleet.

## 🚨 Kiosk Won't Boot

### Check Hardware
- [ ] Power cable connected?
- [ ] Monitor connected and powered on?
- [ ] Boot order set to boot from hard drive?
- [ ] UEFI/BIOS accessible? (Usually DEL, F2, or F12 during boot)

### Check Installation
```bash
# Boot from NixOS USB
# Check if partitions exist
lsblk

# Try mounting the existing installation
mount /dev/disk/by-label/nixos /mnt
mount /dev/disk/by-label/boot /mnt/boot
ls /mnt/etc/nixos  # Should show your flake files
```

### Recovery Steps
```bash
# If files are present, try reinstalling bootloader
nixos-enter --root /mnt
nixos-rebuild switch

# If files are missing, reinstall from scratch
```

---

## 🖥️ Kiosk Boots but No GUI

### Check X Server
```bash
# SSH into kiosk or use TTY (Ctrl+Alt+F2)
systemctl status display-manager

# View logs
journalctl -u display-manager -n 50

# Manually start display manager
systemctl start display-manager
```

### Check Video Drivers
```bash
# Check if GPU is detected
lspci | grep -i vga

# Check Xorg log
cat /var/log/X.0.log | grep -i error

# Test if X can start
startx
```

### Common Fixes
```bash
# Restart display manager
systemctl restart display-manager

# Rebuild system
nixos-rebuild switch

# Check if openbox is installed
which openbox
```

---

## 🌐 Chrome Won't Launch or Shows Error

### Check Chrome Process
```bash
# Check if Chrome is running
ps aux | grep chrome

# Kill and restart Chrome
pkill chrome
su - kiosk
DISPLAY=:0 google-chrome-stable --kiosk "https://login.experienceco.com"
```

### Check Openbox Autostart
```bash
# View the autostart file
cat /home/kiosk/.config/openbox/autostart

# Check for errors
cat /home/kiosk/.xsession-errors

# Verify permissions
ls -la /home/kiosk/.config/openbox/
```

### Manual Chrome Test
```bash
# Become kiosk user
su - kiosk

# Test Chrome in normal mode first
DISPLAY=:0 google-chrome-stable https://login.experienceco.com

# If that works, test kiosk mode
DISPLAY=:0 google-chrome-stable --kiosk https://login.experienceco.com
```

### Chrome-Specific Issues

**Black Screen**: Usually GPU acceleration issue
```bash
# Edit kiosk-common.nix, add to Chrome command:
--disable-gpu \
--disable-software-rasterizer \
```

**Crash on Launch**: Check for profile corruption
```bash
rm -rf /home/kiosk/.config/google-chrome
```

**Certificate Errors**: Time/date wrong
```bash
# Check system time
date

# Set correct timezone in kiosk-common.nix
time.timeZone = "America/New_York";
```

---

## 🌍 Network Issues

### Check Network Status
```bash
# Check network interfaces
ip addr show

# Check if NetworkManager is running
systemctl status NetworkManager

# Check connections
nmcli device status
nmcli connection show
```

### WiFi Not Working
```bash
# Scan for networks
nmcli device wifi list

# Connect to network
nmcli device wifi connect "SSID" password "PASSWORD"

# Make connection auto-connect
nmcli connection modify "SSID" connection.autoconnect yes

# Check WiFi hardware
lspci | grep -i network
```

### Ethernet Not Working
```bash
# Check cable is plugged in
ip link show

# Bring interface up
ip link set eth0 up

# Get DHCP address
dhclient eth0

# Check if NetworkManager is managing it
nmcli device status
```

### DNS Issues
```bash
# Test DNS
nslookup login.experienceco.com

# Check resolv.conf
cat /etc/resolv.conf

# Test direct IP connection
ping 8.8.8.8

# If IP works but DNS doesn't, add to kiosk-common.nix:
networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];
```

---

## 🔄 Updates Not Working

### Check Auto-Upgrade Service
```bash
# Check status
systemctl status nixos-upgrade.service
systemctl status nixos-upgrade.timer

# View logs
journalctl -u nixos-upgrade.service -n 50

# Manually trigger update
systemctl start nixos-upgrade.service
```

### Check Flake Configuration
```bash
# Verify flake URL in config
grep "flake =" /etc/nixos/kiosk-common.nix

# Test flake access
nix flake show github:YOUR_USERNAME/kiosk-fleet

# Force update with refresh
nixos-rebuild switch --flake github:YOUR_USERNAME/kiosk-fleet#kiosk-01 --refresh
```

### GitHub Access Issues
```bash
# Check if GitHub is accessible
ping github.com
curl -I https://github.com

# If behind proxy, add to kiosk-common.nix:
networking.proxy.default = "http://proxy.example.com:8080";
```

### Git Authentication Issues
```bash
# For private repos, set up SSH keys or access tokens
# Generate SSH key
ssh-keygen -t ed25519

# Add to GitHub
cat ~/.ssh/id_ed25519.pub
```

---

## 💾 Disk Space Issues

### Check Disk Usage
```bash
# Check overall usage
df -h

# Check largest directories
du -h /nix/store | sort -h | tail -20

# Count generations
nix-env --list-generations --profile /nix/var/nix/profiles/system
```

### Clean Up
```bash
# Delete old generations (keep last 3)
nix-env --delete-generations +3 --profile /nix/var/nix/profiles/system

# Run garbage collection
nix-collect-garbage -d

# Optimize store (can take time)
nix-store --optimize

# Check space again
df -h
```

### Prevent Future Issues
```bash
# In kiosk-common.nix, adjust:
nix.gc = {
  automatic = true;
  dates = "daily";  # More frequent
  options = "--delete-older-than 7d";  # More aggressive
};
```

---

## 🔐 SSH Access Issues

### Can't Connect
```bash
# From your workstation
ssh root@kiosk-01.local

# If that fails, try IP
ssh root@192.168.1.100

# Check SSH is running on kiosk (from console)
systemctl status sshd

# Start SSH if not running
systemctl start sshd
```

### Permission Denied
```bash
# Check authorized keys
cat /root/.ssh/authorized_keys

# Verify SSH config allows root login
cat /etc/ssh/sshd_config | grep PermitRootLogin

# Check firewall
iptables -L | grep 22
```

### Key Issues
```bash
# On your workstation, check key permissions
ls -la ~/.ssh/id_*
# Should be 600 for private keys

# Test with verbose output
ssh -v root@kiosk-01.local
```

---

## 🎨 Display Issues

### Wrong Resolution
```bash
# Check current resolution
xrandr

# Set resolution (example)
xrandr --output HDMI-1 --mode 1920x1080

# Make permanent in kiosk-common.nix:
services.xserver.xrandrHeads = [
  { output = "HDMI-1"; primary = true; }
];
```

### Multiple Monitors
```bash
# Detect monitors
xrandr

# Configure in kiosk-common.nix:
services.xserver.xrandrHeads = [
  { output = "HDMI-1"; primary = true; }
  { output = "HDMI-2"; monitorConfig = ''
    Option "RightOf" "HDMI-1"
  ''; }
];
```

### Screen Blanking Despite Settings
```bash
# Check DPMS status
xset q | grep DPMS

# Disable manually
xset s off
xset -dpms

# Add to openbox autostart in kiosk-common.nix (already included)
```

---

## 🔧 System Won't Build

### Syntax Errors
```bash
# Check flake syntax
nix flake check

# Show error details
nix flake check --show-trace

# Validate individual files
nix-instantiate --parse kiosk-common.nix
```

### Missing Dependencies
```bash
# Update flake lock
nix flake update

# Check what would be built
nixos-rebuild dry-build --flake .#kiosk-01
```

### Hardware Config Issues
```bash
# Regenerate hardware config
nixos-generate-config --show-hardware-config

# Compare with your hardware-configuration.nix
```

---

## 🆘 Emergency Recovery

### Boot into Older Generation
```bash
# At boot, select older generation from bootloader menu
# Or from running system:
nixos-rebuild switch --rollback
```

### Boot from USB and Chroot
```bash
# Boot NixOS USB
mount /dev/disk/by-label/nixos /mnt
mount /dev/disk/by-label/boot /mnt/boot
nixos-enter --root /mnt

# Now you can rebuild or fix configs
cd /etc/nixos
git log  # See what changed
git checkout HEAD~1  # Revert to previous commit
nixos-rebuild switch
```

### Complete Reinstall
```bash
# Backup hardware-configuration.nix first
cp /mnt/etc/nixos/hardware-configuration.nix /tmp/

# Follow QUICKSTART.md installation steps
```

---

## 📊 Monitoring Commands

### Quick Health Check
```bash
# Run all these on the kiosk
uptime                          # How long running
free -h                         # Memory usage
df -h                           # Disk space
systemctl --failed              # Failed services
journalctl -p err -n 20        # Recent errors
ps aux | grep chrome           # Chrome running?
ping -c 3 login.experienceco.com  # Network OK?
```

### Detailed Diagnostics
```bash
# System info
nixos-version
uname -a

# Hardware
lspci
lsusb
lscpu

# Network
ip addr
ip route
nmcli general status

# Services
systemctl list-units --type=service --state=failed
```

---

## 📞 When to Ask for Help

If you've tried the above and still have issues:

1. Gather information:
   ```bash
   # Run these and save output
   nixos-version > /tmp/debug.txt
   systemctl status >> /tmp/debug.txt
   journalctl -b >> /tmp/debug.txt
   dmesg >> /tmp/debug.txt
   ```

2. Check NixOS discourse: https://discourse.nixos.org
3. Check NixOS wiki: https://nixos.wiki
4. Open an issue in your kiosk-fleet repository with the debug info

Remember: Most issues are configuration problems that can be fixed by editing
kiosk-common.nix and rebuilding!
