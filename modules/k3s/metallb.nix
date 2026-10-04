{ config, lib, ... }:
{
  config = lib.mkIf config.homelab.k3s.enable {
    services.k3s.autoDeployCharts.metallb = {
      name = "metallb";
      repo = "https://metallb.github.io/metallb";
      version = "0.16.1";
      hash = "sha256-+wa7WE/LeFbxVzOypqKv9bYbXDUGh+NBwWOuJKWTitw=";
      targetNamespace = "metallb-system";
      createNamespace = true;
    };

    services.k3s.manifests.metallb-pool.content = {
      apiVersion = "metallb.io/v1beta1";
      kind = "IPAddressPool";
      metadata = { name = "lan"; namespace = "metallb-system"; };
      spec.addresses = [ "10.33.2.1-10.33.2.254" ];
    };

    services.k3s.manifests.metallb-l2.content = {
      apiVersion = "metallb.io/v1beta1";
      kind = "L2Advertisement";
      metadata = { name = "lan"; namespace = "metallb-system"; };
      spec = {
        ipAddressPools = [ "lan" ];
        interfaces = [ config.homelab.k3s.lanInterface ];
      };
    };
  };
}
