{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";   # current stable
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nixidy.url = "github:arnarg/nixidy/latest";
    nixidy.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, disko, sops-nix, nixidy, ... }:
  let
    mkHost = name: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        ./modules/host-common.nix
        ./modules/home-wifi.nix
        ./modules/k3s
        ./hosts/${name}
        { networking.hostName = name; }
      ];
    };
  in {
    nixosConfigurations = nixpkgs.lib.genAttrs [ "inferno" "dungeon" "necro" ] mkHost // {
      # build with nixos-rebuild build-image --image-variant iso-installer --flake .#installer
      installer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ lib, ... }: {
            networking.hostName = "installer";
            users.users.root.openssh.authorizedKeys.keys = import ./modules/ssh-keys.nix;
            systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
          })
        ];
      };
    };
    devShells.x86_64-linux.default =
      let pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in pkgs.mkShellNoCC {
        packages = [ pkgs.nixos-rebuild pkgs.age pkgs.ssh-to-age pkgs.sops pkgs.k9s nixidy.packages.x86_64-linux.default ];
        shellHook = ''export PS1="(homelab) $PS1"'';
      };
    nixidyEnvs.x86_64-linux = nixidy.lib.mkEnvs {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      envs.prod.modules = [ ./k8s/env/prod.nix ];
    };
  };
}
