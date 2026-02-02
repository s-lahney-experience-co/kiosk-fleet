# This is a template hardware configuration
# You'll need to replace this with the actual hardware-configuration.nix
# generated during NixOS installation on each machine
#
# During installation, NixOS generates this file automatically based on
# your hardware. Copy it from /etc/nixos/hardware-configuration.nix

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # This is a TEMPLATE - replace with your actual hardware config
  # Common settings for small computers:
  
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ]; # Change to "kvm-amd" for AMD processors
  boot.extraModulePackages = [ ];

  # File systems - UPDATE THESE with your actual UUIDs from installation
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
    fsType = "ext4";
    options = [ "noatime" "nodiratime" ]; # Reduces writes for microSD longevity
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/XXXX-XXXX";
    fsType = "vfat";
    options = [ "noatime" ]; # Reduces writes
  };

  # Swap file (optional)
  # swapDevices = [ {
  #   device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
  # } ];

  # Networking hardware
  networking.useDHCP = lib.mkDefault true;

  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # For AMD: hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Graphics drivers (for integrated graphics)
  hardware.opengl = {
    enable = true;
    driSupport = true;
  };
}
