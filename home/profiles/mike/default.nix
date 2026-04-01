{ config, lib, pkgs, system, inputs, ... }:

{
  imports = [
    ../base
  ];

  # Override: macOS-specific oh-my-zsh plugin
  modules.shell.zsh.ohmyzsh.plugins = [ "git" "macos" "docker" ]; 

  # Greeting
  modules.shell.zsh.extraConfig = lib.mkAfter ''
    echo "Welcome to your development environment, Mike!"
    echo "Remember to stay hydrated and take breaks while coding!"
  '';

  # Git Identity
  programs.git = {
    userName = "architectureman";
    userEmail = "vnknowledge2014@gmail.com";
  };
  
  # macOS-specific packages (thêm ngoài base)
  home.packages = with pkgs; [
    # Thêm packages riêng cho Mike tại đây
  ];
}