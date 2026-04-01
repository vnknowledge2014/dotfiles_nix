{ config, lib, pkgs, system, inputs, ... }:

{
  imports = [
    ../base
  ];

  # Override: Ubuntu-specific oh-my-zsh plugin
  modules.shell.zsh.ohmyzsh.plugins = [ "git" "ubuntu" "docker" ];

  # Greeting
  modules.shell.zsh.extraConfig = lib.mkAfter ''
    echo "Welcome to your Ubuntu development environment, RND!"
    echo "Remember to stay hydrated and take breaks while coding!"
  '';

  # Git Identity
  programs.git = {
    userName = "architectureman";
    userEmail = "vnknowledge2014@gmail.com";
  };

  # Ubuntu-specific packages (thêm ngoài base)
  home.packages = with pkgs; [
    incus  # Ubuntu-specific container tool
  ];

  # Ubuntu-specific env vars
  home.sessionVariables = {
    PATH = lib.mkForce "$HOME/.cargo/bin:$HOME/.local/bin:/snap/bin:$PATH";
  };
}
