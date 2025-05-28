{ config, lib, pkgs, ... }:

{
  # Cấu hình chung cho tất cả hệ thống NixOS
  
  # Cấu hình Nix
  nix = {
    enable = true;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
  
  # Gói phần mềm cơ bản
  environment.systemPackages = with pkgs; [

  ];
  
  # Cài đặt ngôn ngữ và khu vực
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Cấu hình shell mặc định
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  
  # Cấu hình bảo mật cơ bản
  security.sudo.wheelNeedsPassword = true;
}