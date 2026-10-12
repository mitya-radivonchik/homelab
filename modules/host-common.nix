# configuration.nix: base config for a headless homelab machine.
# Imported from flake.nix together with disk-config.nix and hardware-configuration.nix.
{ config, pkgs, lib, ... }:

let
  sshKeys = import ./ssh-keys.nix;
in
{
  # --- Boot -------------------------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Networking -------------------------------------------------------
  networking.useDHCP = lib.mkDefault true;
  networking.firewall.enable = true;   # openssh opens port 22 on its own
  networking.firewall.logReversePathDrops = true;
  networking.useNetworkd = true;

  # --- Sops -------------------------------------------------------------
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # --- Locale -----------------------------------------------------------
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  # --- SSH --------------------------------------------------------------
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # --- Users ------------------------------------------------------------
  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  users.users.mitya = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];   # sudo
    openssh.authorizedKeys.keys = sshKeys;
  };

  # No password prompt for sudo. Convenient for remote deploys
  # (nixos-rebuild --use-remote-sudo); remove if you'd rather set a password.
  security.sudo.wheelNeedsPassword = false;

  # --- Nix itself -------------------------------------------------------
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
  ];

  services.fstrim.enable = true;
}
