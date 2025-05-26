{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.dev.git;
in {
  options.modules.dev.git = {
    enable = mkEnableOption "Enable git configuration";
    
    aliases = mkOption {
      type = types.attrsOf types.str;
      default = {
        co = "checkout";
        ci = "commit";
        st = "status";
        br = "branch";
        hist = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";
      };
      description = "Git aliases";
    };
    
    extraConfig = mkOption {
      type = types.attrsOf types.anything;
      default = {
        init.defaultBranch = "main";
        pull.rebase = false;
      };
      description = "Extra git configuration";
    };
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      aliases = cfg.aliases;
      extraConfig = cfg.extraConfig;
    };
  };
}