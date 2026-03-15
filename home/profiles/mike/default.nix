{ config, lib, pkgs, system, inputs, ... }:

{
  imports = [
    ../base
  ];

  # Override specific settings for Mike
  modules.shell.zsh.ohmyzsh.plugins = [ "git" "macos" "docker" ]; 

  # Greeting message override
  modules.shell.zsh.extraConfig = lib.mkAfter ''
    echo "Welcome to your development environment, Mike!"
    echo "Remember to stay hydrated and take breaks while coding!"
  '';

  # Git Identity
  programs.git = {
    userName = "architectureman";
    userEmail = "vnknowledge2014@gmail.com";
  };
  
  # Mike specific packages
  home.packages = with pkgs; [
    # Any extra packages for Mike
  ];
}