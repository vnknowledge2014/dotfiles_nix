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
        # Thêm các package cụ thể cho rnd
      ];
    };
    
    shell = {
      enable = true;
      zsh = {
        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;
        enable = true;
        ohmyzsh = {
          enable = true;
          theme = "robbyrussell";
          plugins = [ "git" "docker" ];
        };
        aliases = {
          ll = "ls -l";
          la = "ls -la";
        };
      };
    };
    
    dev.git = {
      enable = true;
    };
    
    editors = {
      enable = true;
      neovim.enable = true;
      vscode.enable = true;
    };
  };

  # Các package cá nhân
  home.packages = with pkgs; [
    inputs.zen-browser.packages.${system}.default
  ];

  # Cấu hình Git cá nhân
  programs.git = {
    userName = "rnd";
    userEmail = "rnd@example.com";  # Cập nhật email thực tế
  };

  # Phiên bản Home Manager
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}