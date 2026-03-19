{ config, lib, pkgs, hostname, ... }:

# Machine-specific overrides for macbook (mike's MacBook)
# This file is automatically imported if hostname matches

{
  # Docker runtime - Colima
  programs.zsh.initContent = lib.mkAfter ''
    export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"

    # Antigravity PATH & Alias (Declarative Setup)
    export PATH="/Applications/Antigravity.app/Contents/Resources/app/bin:$PATH"
    alias antigravity='/Applications/Antigravity.app/Contents/Resources/app/bin/antigravity'
  '';

  # Machine-specific packages
  home.packages = with pkgs; [
    # Add machine-specific packages here
  ];

  # Machine-specific session variables
  home.sessionVariables = {
    # DOCKER_HOST already set in initContent
  };
}
