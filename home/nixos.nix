{ config, lib, pkgs, system, inputs, hostname, username, ... }:

let
  # Check if machine-specific config exists
  machineConfigPath = ./profiles/${username}/machines/${hostname}.nix;
  hasMachineConfig = builtins.pathExists machineConfigPath;
in
{
  # Import hồ sơ người dùng và các module (+ machine-specific nếu tồn tại)
  imports = [ 
    ./modules/core
    ./modules/shell
    ./modules/dev/git.nix
    ./modules/editors
    ./modules/terminal
    ./profiles/${username}
  ] ++ lib.optional hasMachineConfig machineConfigPath;

  # Kích hoạt terminal module (tmux)
  modules.terminal.enable = true;
  
  # Thông tin cơ bản
  home.username = username;
  home.homeDirectory = "/home/${username}";
  
  # Các gói cơ bản cho NixOS
  home.packages = with pkgs; [
    
  ];

  # Phiên bản Home Manager
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}