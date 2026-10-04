# configuration.nix: base config for a headless homelab machine.
# Imported from flake.nix together with disk-config.nix and hardware-configuration.nix.
{ config, pkgs, lib, ... }:

let
  sshKeys = [
    "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGiWfcoplal9hGHnp23iMZucT871DAmj9J185TG60RFtpNgnSYthoZhUmm/tACIPZ1uO6zPNnayZgWbEzXy++515AE5NG7C7AvE+LihTdptoVVI+f9Hk65Oi9FOurN66x26JjWEoLdqMWMlsY3xf23VMp91EFHS3CPkAKw3sYGdqX/f4Q=="
  ];
in
{
  # --- Boot -------------------------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Networking -------------------------------------------------------
  networking.useDHCP = lib.mkDefault true;
  networking.firewall.enable = true;   # openssh opens port 22 on its own
  networking.useNetworkd = true;

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

  # The NixOS release this machine was first installed with. It controls
  # stateful defaults (database formats etc.), NOT which version you run.
  # Set it once at install time and don't bump it on upgrades.
  system.stateVersion = "26.05";
}
