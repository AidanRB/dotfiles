# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      #<home-manager/nixos>
    ];

  fileSystems = {
    "/".options = [ "compress=zstd" ];
    "/home".options = [ "compress=zstd" ];
    "/nix".options = [ "compress=zstd" "noatime" ];
  };
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
  swapDevices = [ { device = "/swap/swapfile"; } ];
  
  boot = {
    supportedFilesystems = [ "ntfs" ];

    # hibernation swapfile support
    kernelParams = [ "resume_offset=13116672" "clearcpuid=304" ]; # hibernation, the finals
    resumeDevice = "/dev/nvme0n1p5";

    # Bootloader
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 0;
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
    };

    # fix for the finals (doesn't work but no downsides?)
    kernel.sysctl."vm.max_map_count" = 2147483642;
  };

  # hibernate after 30m asleep in suspend-then-hibernate
  systemd.sleep.extraConfig = "HibernateDelaySec=30m";

  # hardware support
  # services.hardware.openrgb.enable = true;
  services.ratbagd.enable = true;
  # services.xserver.videoDrivers = [ "amdgpu" ]; # unnecessary after Linux 6.1.75
  
  networking.hostName = "blackbox"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # System properties
  time = {
    timeZone = "America/New_York";
    hardwareClockInLocalTime = true;
  };
  i18n.defaultLocale = "en_US.utf8";

  # GNOME
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.gnome.gnome-keyring.enable = true;
  environment.gnome.excludePackages = (with pkgs; [
    gnome-tour
    gnome-photos
  ]) ++ (with pkgs.gnome; [
    epiphany
    geary
    gnome-maps
    simple-scan
    gnome-music
  ]);

  # Allow installing extensions
  services.gnome.gnome-browser-connector.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.aidan = {
    isNormalUser = true;
    description = "Aidan Bennett";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
    packages = (with pkgs; [
      bibata-cursors

      # games
      steam
      gamehub
      granatier
      oh-my-git
      superTuxKart
      prismlauncher
      lunar-client
      osu-lazer-bin
      gamehub

      # web
      brave
      google-chrome
        chrome-gnome-shell
      firefox
      discord

      # tools
      gnome.gnome-tweaks
      qflipper
      speedcrunch
      flameshot
      helvum
      easyeffects
      piper
      nmap
      dig
      nextcloud-client
      qownnotes
      appeditor

      vscode-fhs
        jdk17
        nixpkgs-fmt
      gcolor3

      # multimedia
      #inkscape
      vlc
      obs-studio
      libreoffice
      hunspell
      hunspellDicts.en_US
      kdenlive
        mediainfo
      mumble

    ]) ++ (with pkgs.gnomeExtensions; [
      # gnome extensions
      alphabetical-app-grid
      appindicator
      custom-hot-corners-extended
      forge
      gesture-improvements
      grand-theft-focus
      gsconnect
      hide-activities-button
      pano
      quick-settings-audio-panel
      removable-drive-menu
      tailscale-status
      tiling-assistant
      vitals
    ]);

    shell = pkgs.fish;
  };

  environment.variables = {
    EDITOR = "micro";
    VISUAL = "micro";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # terminal
    micro
      xclip
    bat
    eza
    tldr

    # dev
    git
    python311
    python311Packages.ipykernel
    python311Packages.yapf

    # usb device redirection in virt-manager
    # spice-gtk
  ];

  # virt-manager with qemu
  # virtualisation = {
  #   libvirtd.enable = true;
  #   spiceUSBRedirection.enable = true;
  # };
  # programs.virt-manager.enable = true;

  # fully enable steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  programs.fish.enable = true;

  # List services that you want to enable:
  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };
    flatpak.enable = true;
    openssh.enable = true;
  };

  # Fix flatpak cursor (didn't work)
  # fonts.fontDir.enable = true;

  networking = {
    firewall = {
      # Open ports in the firewall.
      # 4567 general
      # 7777 terraria
      # 1714 - 1764 kde connect
      allowedTCPPorts = [ 4567 7777 ];
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
      allowedUDPPorts = [ 4567 7777 ];
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
      # Or disable the firewall altogether.
      # enable = false;
    };
  };

  environment.shellAliases = {
    ls = "eza -F";
    ll = "eza -Flag";
    l = "eza -F";
    la = "eza -Fa";
    sudo = "sudo ";
    ip = "ip --color=auto";
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  # garbage collection
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };
  nix.settings.auto-optimise-store = true;

  # auto upgrade
  system.autoUpgrade = {
    enable = true;
    operation = "boot";
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}
