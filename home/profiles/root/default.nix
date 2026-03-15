{ config, lib, pkgs, system, inputs, ... }:

{
  imports = [
    ../base
  ];

  # Override: minimal oh-my-zsh plugins for root
  modules.shell.zsh.ohmyzsh.plugins = [ "git" "docker" ];

  # Git Identity (root/default)
  programs.git = {
    userName = "Your Name";
    userEmail = "your.email@example.com";
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };
}