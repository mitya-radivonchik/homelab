{ config, lib, pkgs, ... }:
let
  cfg = config.homelab.k3s;
in
{
  imports = [ ./metallb.nix ./api-vip.nix ];

  options.homelab.k3s = {
    enable = lib.mkEnableOption "k3s server (embedded etcd)";
    lanInterface = lib.mkOption {
      type = lib.types.str;
      description = "NIC facing the homelab LAN (node-to-node traffic).";
    };
    apiVip = lib.mkOption {
      type = lib.types.str;
      default = "10.33.0.19";
      description = "Floating IP for the Kubernetes API, held by one healthy server at a time (see api-vip.nix).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = !(config.services.k3s.clusterInit && config.services.k3s.serverAddr != "");
      message = "k3s: set clusterInit (bootstrap a brand-new cluster) or serverAddr (join an existing one), not both.";
    }];

    sops.secrets.k3s-token.sopsFile = ../../secrets/k3s.yaml;

    services.k3s = {
      enable    = true;
      role      = "server";
      package   = pkgs.k3s_1_35;
      tokenFile = config.sops.secrets.k3s-token.path;
      # Every server joins through the VIP. Ignored once a node has etcd data on disk,
      # so it only matters for new or wiped nodes. To bootstrap a brand-new cluster,
      # set on ONE host: clusterInit = true; serverAddr = "";
      serverAddr = lib.mkDefault "https://${cfg.apiVip}:6443";
      disable   = [ "servicelb" ];              # MetalLB replaces it
      extraFlags = [
        "--tls-san=${cfg.apiVip}"
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
