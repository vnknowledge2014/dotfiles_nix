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
  home = {
    username = username;
    homeDirectory = lib.mkForce "/Users/${username}";
    stateVersion = "25.05";
  };
  
  # Kích hoạt các module cơ bản
  modules = {
    core = {
      enable = true;
      packages = with pkgs; [

      ];
    };
    
    dev.git.enable = true;
    editors.enable = true;
    terminal.enable = true;
  };
  
  # Các gói cơ bản cho macOS
  home.packages = with pkgs; [
    # CLI tools
    coreutils
    gnugrep
    findutils
    gnused
    gawk
  ];

  # Darwin-specific activation
  home.activation = {
    fixLaunchAgentsPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/Library/LaunchAgents"
      $DRY_RUN_CMD chmod $VERBOSE_ARG 755 "$HOME/Library/LaunchAgents"
    '';
  };
  
  # Integracja z Homebrew
  programs.zsh.initContent = lib.mkIf config.programs.zsh.enable ''
    # Homebrew integration
    if [ -f /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  '';
  
  # Phiên bản Home Manager
  programs.home-manager.enable = true;
}