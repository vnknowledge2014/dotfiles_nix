{ config, lib, pkgs, hostname, ... }:

# Machine-specific template
# Copy this file and rename to match your hostname
# Example: machines/my-laptop.nix

{
  # Docker runtime configuration
  # Uncomment and modify as needed:
  # programs.zsh.initContent = lib.mkAfter ''
  #   export DOCKER_HOST='unix:///path/to/docker.sock'
  # '';

  # Machine-specific packages
  home.packages = with pkgs; [
    # Add machine-specific packages here
  ];

  # Machine-specific session variables
  home.sessionVariables = {
    # Add machine-specific env vars here
  };
}
