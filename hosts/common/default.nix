{ config, lib, pkgs, ... }:

{
  # Cấu hình chung cho tất cả hệ thống (NixOS, Darwin, WSL)
  
  # Cấu hình Nix cơ bản - áp dụng cho mọi hệ thống
  nix = {
    enable = true;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
  
  # Gói phần mềm cốt lõi cho mọi hệ thống
  environment.systemPackages = with pkgs; [
    neovim
    wezterm
    vscode
    htop
    eza
    wget
    curl
    git
    neofetch
    jq
    zsh
    oh-my-zsh
    ripgrep
    fd
    bat
    tree
    fzf
  ];
}