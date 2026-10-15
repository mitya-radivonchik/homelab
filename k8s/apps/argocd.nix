{ charts, ... }: {
  applications.argocd = {
    namespace = "argocd";
    createNamespace = true;

    helm.releases.argocd = {
      chart = charts.argoproj.argo-cd;
      values.server.service.type = "LoadBalancer";
    };

    syncPolicy.syncOptions.serverSideApply = true;
    syncPolicy.autoSync.prune = false;
  };
}
