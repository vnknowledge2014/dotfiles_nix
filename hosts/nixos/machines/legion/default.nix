{ config, lib, pkgs, ... }:

{
  imports = [];

  networking.hostName = "legion";

  # Placeholder: cần chạy nixos-generate-config trên máy thật
  # để tạo hardware-configuration.nix
  # sudo nixos-generate-config --dir hosts/nixos/machines/legion

  nixpkgs.config = {
    allowUnfree = true;
  };

  # ZFS host ID (cần set trên máy thật)
  # Tạo: head -c 4 /dev/urandom | od -A n -t x4 | tr -d ' '
  networking.hostId = "deadbeef";

  environment.systemPackages = with pkgs; [
    # Các gói đặc thù cho máy legion
  ];

  users.users.rnd = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
  };

  system.stateVersion = "25.05";
}
