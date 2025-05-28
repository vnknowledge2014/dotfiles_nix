{ config, lib, pkgs, system, inputs, ... }:

{
  # Import các module
  imports = [
    ../../modules/core
    ../../modules/shell
    ../../modules/dev/git.nix
    ../../modules/editors
  ];

  # Bật các module
  modules = {
    core.enable = true;
    shell = {
      enable = true;
      zsh = {
        enable = true;
        
        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;
        ohmyzsh = {
          enable = true;
          theme = "robbyrussell";
          plugins = [ "git" "docker" "zsh-autosuggestions" "zsh-syntax-highlighting"];
        };
        aliases = {
          ll = "ls -l";
          la = "ls -la";
        };
      };
    };
    dev.git = {
      enable = true;
      # Thông tin cá nhân
      extraConfig = {
        core.editor = "vim";
      };
    };
    editors.enable = true;
  };

  # Các package cá nhân
  home.packages = with pkgs; [
    # Thêm các package riêng tại đây
  ];

  # Cấu hình Git cá nhân
  programs.git = {
    userName = "Your Name";
    userEmail = "your.email@example.com";
  };

  # Các cấu hình riêng khác
  home.sessionVariables = {
    EDITOR = "vim";
  };

  # Các cấu hình đặc thù cho từng hệ thống
  home.activation = lib.mkIf (builtins.currentSystem == "x86_64-darwin") {
    # Chỉ chạy trên macOS
    fixLaunchAgentsPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/Library/LaunchAgents"
      $DRY_RUN_CMD chmod $VERBOSE_ARG 755 "$HOME/Library/LaunchAgents"
    '';
  };

  # Phiên bản Home Manager
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}