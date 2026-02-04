{ config, pkgs, ... }:

{
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
    flake = "github:s-lahney-experience-co/kiosk-fleet";
    dates = "04:00"; # Daily at 4 AM
    allowReboot = false; # Set to true if you want automatic reboots after updates
    flags = [
      "--update-input" "nixpkgs"
      "--commit-lock-file"
    ];
  };

  # Automatic garbage collection to save disk space
  nix.gc = {
    automatic = true;
    dates = "daily";  # Daily for microSD cards (weekly for larger storage)
    options = "--delete-older-than 30d";
  };

  # Limit number of boot generations (important for microSD cards)
  boot.loader.systemd-boot.configurationLimit = 5;

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

  # Allow camera access
  services.udev.extraRules = ''
    # Allow video group to access webcams
    SUBSYSTEM=="video4linux", GROUP="video", MODE="0660"
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="*", ATTRS{idProduct}=="*", MODE="0660", GROUP="video"
  '';

  # Create .xprofile to launch Google Chrome in kiosk mode
  system.activationScripts.kioskXprofile = ''
    mkdir -p /home/kiosk
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
  --auto-accept-camera-and-microphone-capture \
  --disable-save-password-bubble \
  --start-maximized  &

# Disable screen blanking
sleep 2
DISPLAY=:0 xset s off &
DISPLAY=:0 xset -dpms &
DISPLAY=:0 xset s noblank &

# Hide cursor after inactivity
DISPLAY=:0 unclutter -idle 5 &
EOF
    chmod +x /home/kiosk/.xprofile
    chown kiosk:users /home/kiosk/.xprofile
  '';

  # Enable SSH for remote management (optional but recommended)
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
    settings.PasswordAuthentication = true; # Use SSH keys for production
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

  # Watchdog to reboot if system hangs (optional)
  systemd.watchdog = {
    runtimeTime = "30s";
    rebootTime = "10min";
  };
}
