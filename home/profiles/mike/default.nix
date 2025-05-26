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
    core = {
      enable = true;
      packages = with pkgs; [
        nodejs
        yarn
      ];
    };
    
    shell = {
      enable = true;
      zsh = {
        enable = true;
        ohmyzsh = {
          enable = true;
          theme = "robbyrussell";
          plugins = [ "git" "macos" "docker" "vscode" "npm" "yarn" ];
        };
        aliases = {
          ll = lib.mkForce "eza -l --icons";
          la = lib.mkForce "eza -la --icons";
          cat = lib.mkForce "bat";
          top = lib.mkForce "htop";
          g = lib.mkForce "git";
        };
        extraConfig = ''
          # Historry
          HISTSIZE=10000
          SAVEHIST=10000
          
          # Tích hợp FZF
          if [ -n "$(command -v fzf)" ]; then
            source ${pkgs.fzf}/share/fzf/completion.zsh
            source ${pkgs.fzf}/share/fzf/key-bindings.zsh
          fi
          
          # Greeting message
          echo "Welcome to your macOS development environment, Mike!"
        '';
      };
    };
    
    dev.git = {
      enable = true;
      extraConfig = {
        core.editor = "code --wait";
      };
    };
    
    editors = {
      enable = true;
      neovim.enable = true;
      vscode.enable = true;
    };
  };

  # Các package cá nhân
  home.packages = with pkgs; [
    fzf
    bat
    eza
    htop
  ];

  # Cấu hình Git cá nhân
  programs.git = {
    userName = "architectureman";
    userEmail = "vnknowledge2014@gmail.com";
  };

  # Các cấu hình riêng khác
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "code";
    LANG = "en_US.UTF-8";
    PATH = "$HOME/.local/bin:$PATH";
  };

  # Đảm bảo thư mục LaunchAgents có quyền truy cập đúng
  home.activation = lib.mkIf (system == "x86_64-darwin" || system == "aarch64-darwin") {
    fixLaunchAgentsPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/Library/LaunchAgents"
      $DRY_RUN_CMD chmod $VERBOSE_ARG 755 "$HOME/Library/LaunchAgents"
    '';
  };

  # Phiên bản Home Manager
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}