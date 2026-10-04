{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";   # current stable
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, disko, ... }:
  let
    mkHost = name: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./modules/host-common.nix
        ./hosts/${name}
        { networking.hostName = name; }
      ];
    };
  in {
    nixosConfigurations = nixpkgs.lib.genAttrs [ "inferno" ] mkHost;
    devShells.x86_64-linux.default =
      let pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in pkgs.mkShellNoCC {
        packages = [ pkgs.nixos-rebuild pkgs.age pkgs.ssh-to-age ];
        shellHook = ''export PS1="(homelab) $PS1"'';
      };
  };
}
