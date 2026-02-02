# Changelog

## Version 1.0 - Complete Kiosk Fleet Configuration

### Features Included

#### Core Functionality
- ✅ NixOS Flakes-based immutable OS configuration
- ✅ Centralized configuration management via GitHub
- ✅ Chrome kiosk mode pointing to https://login.experienceco.com
- ✅ Automatic daily updates at 4 AM
- ✅ Atomic rollback capability (5 generations)
- ✅ Remote SSH management

#### Hardware Support
- ✅ **Webcam & Microphone Support**
  - Auto-granted permissions for media devices
  - Camera group permissions configured
  - udev rules for automatic device detection
  - Chrome flags for seamless media access

- ✅ **MicroSD Card Optimization**
  - Optimized for SanDisk MAX Endurance 64GB
  - noatime/nodiratime mount options
  - Daily garbage collection
  - Limited journal size (200MB)
  - 5 boot generations (configurable)
  - Extended card lifespan (5-7 years expected)

#### System Optimization
- ✅ Screen blanking disabled
- ✅ Automatic cursor hiding after inactivity
- ✅ Openbox lightweight window manager
- ✅ NetworkManager for easy WiFi/Ethernet
- ✅ Automatic login to kiosk user
- ✅ Minimal attack surface

### Documentation

#### Complete Guides
- **README.md** - Comprehensive reference (8.9 KB)
- **QUICKSTART.md** - 20-minute deployment guide (2.5 KB)
- **TROUBLESHOOTING.md** - Problem-solving checklist (9.1 KB)
- **WEBCAM_SUPPORT.md** - Webcam setup and testing (7.0 KB)
- **MICROSD_SETUP.md** - MicroSD optimization guide (8.9 KB)
- **ADVANCED_EXAMPLES.md** - Location-specific configs (4.9 KB)

#### Configuration Files
- **flake.nix** - Main fleet configuration
- **kiosk-common.nix** - Shared kiosk settings
- **hardware-configuration.nix** - Hardware template
- **validate.sh** - Configuration validation script
- **.gitignore** - Git repository setup

### Target Hardware

**Recommended:**
- Storage: SanDisk MAX Endurance 64GB microSD
- RAM: 2-4GB
- CPU: Any x86_64 (Intel/AMD)
- Network: Ethernet or WiFi
- Display: HDMI/DisplayPort monitor
- Optional: USB webcam (UVC compatible)

### Installation Time
- Initial setup: ~20 minutes per kiosk
- Updates: Automatic (daily at 4 AM)

### Deployment Scale
- Tested for: 1-100+ kiosks
- Central management: Single GitHub repository
- Update propagation: Automatic pull from GitHub

### Storage Requirements
- Base installation: ~6 GB
- With 5 generations: ~18 GB
- Recommended free space: 45+ GB (on 64GB card)

### Network Requirements
- Initial install: Internet connection required
- Updates: GitHub access required (https://github.com)
- Runtime: Internet required for https://login.experienceco.com

### Security Features
- SSH key authentication (password auth disabled)
- Firewall enabled (only port 22 open)
- Automatic security updates via NixOS channels
- Immutable OS prevents tampering
- Kiosk user has limited permissions

### Maintenance
- Automatic garbage collection: Daily
- Log rotation: Automatic (200MB limit)
- System updates: Daily at 4 AM
- Expected hands-off operation: Years

### Known Limitations
- Chrome requires ~5-10 seconds to launch on first boot
- MicroSD cards slower than SSD (30-60 second boot time)
- Auto-granted webcam permissions apply to all sites (see WEBCAM_SUPPORT.md for restrictions)
- Requires rebuilding system for configuration changes (intentional for immutability)

### Version Information
- NixOS: 24.05 stable
- Chrome: Latest from nixpkgs (auto-updated)
- Configuration schema: Flakes (experimental features enabled)

### Support & Updates
- Configuration managed via Git
- Issues tracked in repository
- Community support via NixOS forums
- Self-documenting configuration files

### License
MIT License - Free to modify and deploy

---

## Getting Started

1. Extract this archive
2. Upload to GitHub (or your preferred Git host)
3. Update `kiosk-common.nix` line 30 with your GitHub username
4. Follow **QUICKSTART.md** for first kiosk installation
5. Clone configuration for additional kiosks

## Questions?

- Hardware setup → **MICROSD_SETUP.md**
- Webcam issues → **WEBCAM_SUPPORT.md**
- System problems → **TROUBLESHOOTING.md**
- Custom configs → **ADVANCED_EXAMPLES.md**
- Everything else → **README.md**

---

**Package Date:** February 2, 2026
**Configuration Version:** 1.0
**Target Use Case:** ExperienceCo Kiosk Fleet
