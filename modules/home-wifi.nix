{ config, ... }:
{
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
}
