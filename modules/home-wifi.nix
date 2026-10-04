{ config, lib, ... }:
let
  homeSubnet = "192.168.178.0/24";
  wifiTable = 200;
in
{
  options.homelab.wifi.enable = lib.mkEnableOption "home wifi";

  config = lib.mkIf config.homelab.wifi.enable {
    assertions = [{
      assertion = config.networking.useNetworkd;
      message = "homelab.wifi needs networking.useNetworkd = true";
    }];

    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    sops.secrets.wireless = {
      sopsFile = ../secrets/home-wifi.yaml;
      owner = "wpa_supplicant";
    };
    networking.wireless = {
      enable = true;
      secretsFile = config.sops.secrets.wireless.path;
      networks."Sanitarium".pskRaw = "ext:psk_home";
    };

    systemd.network.networks."40-wifi" = {
      matchConfig.WLANInterfaceType = "station";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = false;
      };
      dhcpV4Config = {
        RouteTable = wifiTable;
        UseDNS = false;
      };
      linkConfig.RequiredForOnline = "no";
      routingPolicyRules = [
        {
          From = homeSubnet;
          IncomingInterface = "lo";   # match only locally generated packets, never forwarded ones
          Table = wifiTable;
          Priority = 1000;
        }
      ];
    };
  };
}
