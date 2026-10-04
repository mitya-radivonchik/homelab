{ ... }: {
  imports = [ ./hardware-configuration.nix ./disk-config.nix ../../modules/home-wifi.nix ];
  system.stateVersion = "26.05";
}
