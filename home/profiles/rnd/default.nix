{ lib, ... }:

{
  imports = [
    ../base
  ];

  # Profile này dùng chung cho Ubuntu (home/ubuntu.nix) và NixOS-WSL (home/wsl.nix).
  # Những gì riêng của từng OS (plugin "ubuntu", /snap/bin, incus...) nằm ở file OS đó.

  # Greeting
  modules.shell.zsh.extraConfig = lib.mkAfter ''
    echo "Welcome to your development environment, RND!"
    echo "Remember to stay hydrated and take breaks while coding!"
  '';

  # Git Identity
  programs.git.settings.user = {
    name = "architectureman";
    email = "vnknowledge2014@gmail.com";
  };
}
