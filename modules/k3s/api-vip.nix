# Floating IP for the Kubernetes API (kubectl, joining servers, future agents).
# keepalived runs on every k3s server and uses VRRP to elect exactly one of them
# to hold the IP. A server whose own API isn't ready drops out of the election,
# so the IP only ever sits on a node that can actually answer.
{ config, lib, pkgs, ... }:
let
  cfg = config.homelab.k3s;
  tls = "/var/lib/rancher/k3s/server/tls";
  agent = "/var/lib/rancher/k3s/agent";

  # Succeeds only if this node's API server answers /readyz with 200.
  # k3s turns off anonymous API access, so the check authenticates with the
  # low-privilege kube-proxy client cert k3s keeps on every server. Reading
  # its key needs root, hence `user = "root"` below.
  apiReady = pkgs.writeShellScript "k3s-api-ready" ''
    exec ${lib.getExe pkgs.curl} --silent --fail --max-time 2 --output /dev/null \
      --cacert ${tls}/server-ca.crt \
      --cert   ${agent}/client-kube-proxy.crt \
      --key    ${agent}/client-kube-proxy.key \
      https://127.0.0.1:6443/readyz
  '';
in
{
  config = lib.mkIf cfg.enable {
    services.keepalived = {
      enable = true;
      enableScriptSecurity = true;  # refuse to run root scripts that non-root users could modify

      # keepalived uses VRRP, which is its own IP protocol (112), not TCP/UDP
      openFirewall = true;

      vrrpScripts.k3s-api = {
        script   = "${apiReady}";
        user     = "root";
        interval = 2;  # seconds between checks
        timeout  = 3;
        fall     = 2;  # 2 failed checks -> this node gives up the VIP
        rise     = 2;  # 2 passed checks -> this node may hold it again
      };

      vrrpInstances.k3s-api = {
        interface       = cfg.lanInterface;
        virtualRouterId = 19;      # any 1-255; must be unique among VRRP groups on this LAN
        state           = "BACKUP";  # all nodes equal: none is the preferred holder...
        noPreempt       = true;      # ...and a returning node doesn't take the VIP back
        # /32: the VIP only has to answer for itself; the route to the LAN already
        # comes from the node's own address.
        virtualIps   = [ { addr = "${cfg.apiVip}/32"; } ];
        trackScripts = [ "k3s-api" ];
      };
    };
  };
}
