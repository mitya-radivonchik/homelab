{ config, lib, pkgs, ... }:
let
  cfg    = config.homelab.k3s;
  apiVip = "10.33.0.19";
in
{
  imports = [ ./metallb.nix ];

  options.homelab.k3s = {
    enable = lib.mkEnableOption "k3s server (embedded etcd)";
    lanInterface = lib.mkOption {
      type = lib.types.str;
      description = "NIC facing the homelab LAN (node-to-node traffic).";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.k3s-token.sopsFile = ../../secrets/k3s.yaml;

    services.k3s = {
      enable    = true;
      role      = "server";
      package   = pkgs.k3s_1_35;
      tokenFile = config.sops.secrets.k3s-token.path;
      disable   = [ "servicelb" ];              # MetalLB replaces it
      extraFlags = [
        "--tls-san=${apiVip}"
        "--flannel-backend=vxlan"               # explicit: must match on all servers
        "--cluster-cidr=10.42.0.0/16"
        "--service-cidr=10.43.0.0/16"
        "--secrets-encryption"
      ];
      gracefulNodeShutdown.enable = true;
    };

    networking.firewall = {
      allowedTCPPorts = [ 6443 ];               # API: kubectl, and pods -> API
      interfaces.${cfg.lanInterface} = {        # node <-> node, LAN only
        allowedTCPPorts = [ 2379 2380 10250 7946 ];  # etcd client/peer, kubelet, MetalLB
        allowedUDPPorts = [ 8472 7946 ];             # flannel VXLAN, MetalLB
      };
    };
  };
}
