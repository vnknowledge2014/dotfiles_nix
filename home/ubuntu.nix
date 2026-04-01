{ config, lib, pkgs, system, inputs, hostname, username, ... }:

let
  # Check if machine-specific config exists
  machineConfigPath = ./profiles/${username}/machines/${hostname}.nix;
  hasMachineConfig = builtins.pathExists machineConfigPath;
in
{
  # Import các module cơ bản và machine-specific config nếu tồn tại
  imports = [ 
    ./modules/core
    ./modules/shell
    ./modules/dev/git.nix
    ./modules/editors
    ./modules/terminal
    ./profiles/${username}
  ] ++ lib.optional hasMachineConfig machineConfigPath;
  
  # Thông tin cơ bản
  home.username = username;
  home.homeDirectory = "/home/${username}";
  
  # Module enables — base profile đã bật hết, ở đây chỉ cần khai báo tối thiểu
  modules = {
    core.enable = true;
    dev.git.enable = true;
    editors.enable = true;
    terminal.enable = true;
  };
  
  # Phiên bản Home Manager
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
