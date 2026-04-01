{ config, lib, pkgs, hostname, ... }:

# Machine-specific overrides cho Ubuntu PC (rnd)
# File này tự động được import khi hostname = "ubuntu-pc"

{
  # Docker runtime — Docker Engine native trên Ubuntu
  programs.zsh.initContent = lib.mkAfter ''
    export DOCKER_HOST='unix:///var/run/docker.sock'
  '';

  # Machine-specific packages
  home.packages = with pkgs; [
    # Thêm packages riêng cho Ubuntu PC tại đây
  ];

  # Machine-specific session variables
  home.sessionVariables = {
    # DOCKER_HOST already set in initContent
  };
}
