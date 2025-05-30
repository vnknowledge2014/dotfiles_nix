{ config, lib, pkgs, ... }:

{
  # Cấu hình Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Cài đặt môi trường macOS cơ bản
  environment.systemPackages = with pkgs; [
    m-cli  # Tiện ích CLI cho macOS
    mas    # Mac App Store CLI
  ];
  
  # Cấu hình shell
  programs.zsh.enable = true;
  
  # Phiên bản hệ thống
  system.stateVersion = 4;
}