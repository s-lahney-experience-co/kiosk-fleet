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
    chromium
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

  # Create .xprofile to launch Chromium (more reliable than openbox autostart)
  system.activationScripts.kioskXprofile = ''
    mkdir -p /home/kiosk
    cat > /home/kiosk/.xprofile << 'EOF'
#!/bin/bash
# Wait for X server to be fully ready
sleep 5

# Launch Chromium in kiosk mode
DISPLAY=:0 chromium \
  --kiosk \
  --app=https://login.experienceco.com \
  --no-sandbox \
  --no-first-run \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-translate \
  --noerrdialogs \
  --disable-suggestions-service \
  --disable-save-password-bubble \
  --start-maximized \
  --disable-dev-shm-usage \
  --use-fake-ui-for-media-stream \
  --auto-accept-camera-and-microphone-capture &

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
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Watchdog to reboot if system hangs (optional)
  systemd.watchdog = {
    runtimeTime = "30s";
    rebootTime = "10min";
  };
}
