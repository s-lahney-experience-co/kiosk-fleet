{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Allow unfree packages like google-chrome
  nixpkgs.config.allowUnfree = true;
  
  # System state version - don't change this after installation
  system.stateVersion = "24.05";
  
  # Boot loader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Enable networking
  networking.networkmanager.enable = true;
  
  # Time zone
  time.timeZone = "Australia/Sydney";
  
  # Automatic updates from your flake repository
  system.autoUpgrade = {
    enable = true;
    flake = "github:s-lahney-experience-co/kiosk-fleet#${config.networking.hostName}";
    dates = "04:00"; # Daily at 4 AM
    allowReboot = true; # Set to true if you want automatic reboots after updates
    flags = [
      "--update-input" "nixpkgs"
      "--commit-lock-file"
    ];
  };
  
  # Automatic garbage collection to save disk space
  nix.gc = {
    automatic = true;
    dates = "daily";
  };
  
  # Keep only the last 5 system generations
  boot.loader.systemd-boot.configurationLimit = 5;  # Adjust based on your bootloader
  
  
  # Limit journal size to save space
  services.journald.extraConfig = ''
    SystemMaxUse=200M
    SystemMaxFileSize=50M
  '';
  
  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Install required packages
  environment.systemPackages = with pkgs; [
    google-chrome
    vim
    git
    networkmanager
    htop
    unclutter
    xorg.xset
  ];
  
  # X11 windowing system
  services.xserver = {
    enable = true;
    
    # Use a lightweight window manager
    windowManager.openbox.enable = true;
    displayManager.lightdm.enable = true;
  };
  
  # Auto-login for kiosk user (must be outside services.xserver in newer NixOS)
  services.displayManager.autoLogin = {
    enable = true;
    user = "kiosk";
  };
  
  # Disable screen blanking and power management
  services.xserver.serverFlagsSection = ''
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
  '';
  
  # Create kiosk user
  users.users.kiosk = {
    isNormalUser = true;
    description = "Kiosk User";
    extraGroups = [ "networkmanager" "video" "audio" "camera" ];
  };
  
  # SSH access for root user
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINE7ySbyrj28cD02q6vL3Azf0Sx1a0IpMXDQ0skEJY6S workspaces@SBB-WKSTN198"
  ];
  
  # Allow camera access
  services.udev.extraRules = ''
    # Allow video group to access webcams
    SUBSYSTEM=="video4linux", GROUP="video", MODE="0660"
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="*", ATTRS{idProduct}=="*", MODE="0660", GROUP="video"
  '';
  
  # Create .xprofile to launch Google Chrome in kiosk mode
  system.activationScripts.kioskXprofile = ''
    mkdir -p /home/kiosk
    mkdir -p /home/kiosk/.config/openbox
    
    # Create openbox config to force Chrome fullscreen
    cat > /home/kiosk/.config/openbox/rc.xml << 'XMLEOF'
<?xml version="1.0"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <applications>
    <application class="Google-chrome*">
      <fullscreen>yes</fullscreen>
      <maximized>yes</maximized>
      <decor>no</decor>
    </application>
  </applications>
</openbox_config>
XMLEOF
    
    cat > /home/kiosk/.xprofile << 'EOF'
#!/bin/bash
sleep 5
# Set correct user runtime directory
export XDG_RUNTIME_DIR=/run/user/1000
export DISPLAY=:0
export HOME=/home/kiosk
google-chrome \
  --kiosk \
  --app=https://login.experienceco.com \
  --no-sandbox \
  --disable-gpu \
  --no-first-run \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-save-password-bubble \
  --auto-accept-camera-and-microphone-capture \
  --password-store=basic \
  --disable-features=PasswordManager,PasswordManagerOnboarding \
  --disable-password-manager-reauthentication &
sleep 2
DISPLAY=:0 xset s off &
DISPLAY=:0 xset -dpms &
DISPLAY=:0 xset s noblank &
# Hide cursor after inactivity
DISPLAY=:0 unclutter -idle 5 &
EOF
    chmod +x /home/kiosk/.xprofile
    chown -R kiosk:users /home/kiosk/.config
    chown kiosk:users /home/kiosk/.xprofile
  '';
  # Enable SSH for remote management (optional but recommended)
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
    settings.PasswordAuthentication = false;
  };
  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]; # SSH
  };
  # Sound support (in case you need audio)
  services.pulseaudio.enable = false;
  services.pipewire.enable = true;
  services.pipewire.wireplumber.enable = true;
  # Systemd watchdog to reboot if system hangs (optional)
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "30s";
    RebootWatchdogSec = "10min";
  };
  
  
}