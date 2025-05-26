{ config, lib, pkgs, ... }:

{
  # Cấu hình chung cho tất cả hệ thống (NixOS, Darwin, WSL)
  
  # Cấu hình Nix cơ bản - áp dụng cho mọi hệ thống
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
  
  # Gói phần mềm cốt lõi cho mọi hệ thống
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
  ];
}