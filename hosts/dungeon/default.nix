{ ... }: {
  imports = [ ./hardware-configuration.nix ./disk-config.nix ];
 # The NixOS release this machine was first installed with. It controls
 # stateful defaults (database formats etc.), NOT which version you run.
 # Set it once at install time and don't bump it on upgrades.
  system.stateVersion = "26.05";

  homelab.wifi.enable = false;

  homelab.k3s.enable = false;
  homelab.k3s.lanInterface = "eno1";
  services.k3s = {
    nodeIP      = "10.33.0.21"; # has to match the static DHCP lease for dungeon lan
    clusterInit = true;   # first boot only; swap for serverAddr once more nucs arrive
  };
}
