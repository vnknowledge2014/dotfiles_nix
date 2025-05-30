{ config, lib, pkgs, ... }:

with lib;

let
  # Common Homebrew configurations
  commonBrews = [

  ];
  
  commonCasks = [
    
  ];
  
  commonMasApps = {
    
  };
in
{
  options = {
    extraBrews = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional Homebrew packages to install";
    };

    extraCasks = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional Homebrew casks to install";
    };

    extraMasApps = mkOption {
      type = types.attrsOf types.int;
      default = {};
      description = "Additional Mac App Store apps to install";
    };
  };

  config = {
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
      };
      
      global.brewfile = true;
      
      # Combine common and extra packages
      brews = commonBrews ++ config.extraBrews;
      casks = commonCasks ++ config.extraCasks;
      masApps = commonMasApps // config.extraMasApps;
    };

    environment.shellInit = ''
      if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    '';
  };
}