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
    
    # Auto-login for kiosk user
    displayManager.autoLogin = {
      enable = true;
      user = "kiosk";
    };
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
    # Set a password or leave it locked for security
    # initialPassword = "changeme"; # Uncomment if you need local access
  };

  # Allow camera access
  services.udev.extraRules = ''
    # Allow video group to access webcams
    SUBSYSTEM=="video4linux", GROUP="video", MODE="0660"
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="*", ATTRS{idProduct}=="*", MODE="0660", GROUP="video"
  '';

  # Create openbox config directory for kiosk user
  system.activationScripts.kioskOpenboxConfig = ''
    mkdir -p /home/kiosk/.config/openbox
    cat > /home/kiosk/.config/openbox/autostart << 'EOF'
# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Hide cursor after 5 seconds of inactivity
unclutter -idle 5 &

# Wait for X to be ready
sleep 3

# Launch Chromium in kiosk mode
chromium \
  --kiosk \
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
  --auto-accept-camera-and-microphone-capture \
  "https://login.experienceco.com" &
EOF
    chown -R kiosk:users /home/kiosk/.config
  '';

  # Systemd user service to launch Chromium reliably
  systemd.user.services.kiosk-chromium = {
    description = "Kiosk Chromium Browser";
    after = [ "graphical-session.target" ];
    wantedBy = [ "default.target" ];
    environment = {
      DISPLAY = ":0";
    };
    serviceConfig = {
      Type = "simple";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      ExecStart = ''
        ${pkgs.chromium}/bin/chromium \
          --kiosk \
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
          --auto-accept-camera-and-microphone-capture \
          https://login.experienceco.com
      '';
      Restart = "always";
      RestartSec = "5";
    };
  };

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
