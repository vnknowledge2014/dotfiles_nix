{ config, lib, pkgs, hostname, ... }:

# Machine-specific overrides for macbook (mike's MacBook)
# This file is automatically imported if hostname matches

{
  # Docker runtime - Colima
  # NOTE: DOCKER_HOST is auto-detected in base/default.nix via socket check
  # (unix://$HOME/.colima/default/docker.sock when Colima running, or /var/run/docker.sock on Linux)
  # Do NOT hard-code DOCKER_HOST here — it bypasses the safety check and causes
  # "cannot connect to docker daemon" errors when Colima is stopped/crashed.
  programs.zsh.initContent = lib.mkAfter ''
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
    # DOCKER_HOST is auto-detected in base/default.nix (socket-safe check)
  };
}
