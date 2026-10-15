{
  imports = [ ../apps/argocd.nix ];

  nixidy.target.repository = "http://10.33.0.10:30142/mitya/homelab.git";
  nixidy.target.branch = "master";
  nixidy.chartsDir = ../charts;
  nixidy.k8sVersion = "1.35";

  nixidy.defaults.syncPolicy.autoSync = {
    enable = true;
    selfHeal = true;
    prune = true;
  };
}
