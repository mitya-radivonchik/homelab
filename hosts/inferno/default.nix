{ ... }: {
  imports = [ ./hardware-configuration.nix ./disk-config.nix ];
 # The NixOS release this machine was first installed with. It controls
 # stateful defaults (database formats etc.), NOT which version you run.
 # Set it once at install time and don't bump it on upgrades.
  system.stateVersion = "26.05";

  homelab.wifi.enable = true;
}
