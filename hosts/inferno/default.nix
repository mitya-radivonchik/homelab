{ ... }: {
  imports = [ ./hardware-configuration.nix ./disk-config.nix ];
  system.stateVersion = "26.05";
  homelab.wifi.enable = true;
}
