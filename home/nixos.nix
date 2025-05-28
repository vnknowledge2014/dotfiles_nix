{ config, pkgs, system, inputs, hostname, username, ... }:

{
  # Import hồ sơ người dùng và các module
  imports = [ 
    ./modules/core
    ./modules/shell
    ./modules/dev/git.nix
    ./modules/editors
    ./profiles/${username}
  ];
  
  # Thông tin cơ bản
  home.username = username;
  home.homeDirectory = "/home/${username}";
  
  # Các gói cơ bản cho NixOS
  home.packages = with pkgs; [
    
  ];

  # Phiên bản Home Manager
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}