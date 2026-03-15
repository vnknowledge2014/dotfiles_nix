{ config, lib, pkgs, hostname, ... }:

# Machine-specific overrides for macbook (mike's MacBook)
# This file is automatically imported if hostname matches

{
  # Docker runtime - OrbStack for this machine
  programs.zsh.initContent = lib.mkAfter ''
    # export DOCKER_HOST='unix:///var/folders/hf/z_4jqsxs05b28y3_qt8j7tmh0000gn/T/podman/podman-machine-default-api.sock'
    export DOCKER_HOST='unix:///Users/mike/.orbstack/run/docker.sock'

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
