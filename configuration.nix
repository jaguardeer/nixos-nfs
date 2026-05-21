# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ];

# Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "console=ttyS0,115200n8" ];

  networking.hostName = "nixos-nfs"; # Define your hostname.

# Configure network connections interactively with nmcli or nmtui.
    networking.networkmanager.enable = true;

# Set your time zone.
  time.timeZone = "America/Chicago";

# don't require password for sudo
  security.sudo.wheelNeedsPassword = false;
# disable root account
  users.users.root.hashedPassword = "!";
# Define a user account. Don't forget to set a password with `passwd`.
  users.users.my-username = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable `sudo` for the user.
      packages = with pkgs; [
      tree
      ];
  };

# point to point wireguard setup
  networking.wireguard.interfaces.wg0 = {
    ips = [ "192.168.0.2/32" ];
    postSetup = ''
      ip addr add 192.168.0.2/32 peer 192.168.0.1/32 dev wg0
    '';
    preShutdown = ''
      ip addr del 192.168.0.2/32 peer 192.168.0.1/32 dev wg0
    '';
    listenPort = 51820;
    privateKeyFile = "/etc/wireguard/wg0.key"; # generate out-of-band `wg genkey >/etc/wireguard/wg0.key`
    peers = [
      {
        presharedKeyFile = "/etc/wireguard/wg0.psk"; # generate out-of-band
        publicKey = "<peer-public-key-here>";
        allowedIPs = [ "192.168.0.1/32" ];
      }
    ];
  };
  
  


# List packages installed in system profile.
# You can use https://search.nixos.org/ to find more packages (and options).
# environment.systemPackages = with pkgs; [
#   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
# ];

# List services that you want to enable:

# nfs setup
  services.nfs.server = {
    enable = true;
    exports = ''
      /srv/nfs 192.168.0.0/24(rw,sync,no_subtree_check,no_root_squash)
    '';
  };
# allow NFS on wireguard only
  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.firewall.interfaces.wg0.allowedUDPPorts = [ 2049 ];
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 2049 ];

# Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
    hostKeys = [
    {
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    ];
    extraConfig = ''
      TrustedUserCAKeys /etc/ssh/user-ca-keys
      HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub
      '';
  };
  environment.etc."ssh/user-ca-keys" = {
    text = "<contents of /etc/ssh/user-ca-keys file>";
    mode = "0644";
  };

# Copy the NixOS configuration file and link it from the resulting system
# (/run/current-system/configuration.nix). This is useful in case you
# accidentally delete configuration.nix.
# system.copySystemConfiguration = true;

# NEVER CHANGE THIS
  system.stateVersion = "25.11"; # Never change this
}