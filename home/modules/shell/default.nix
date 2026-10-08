{ config, lib, ... }:

with lib;
let
  cfg = config.modules.shell;
in
{
  options.modules.shell = {
    enable = mkEnableOption "Enable shell configuration";

    zsh = {
      enable = mkEnableOption "Enable zsh configuration";

      autosuggestions = {
        enable = mkEnableOption "Enable zsh autosuggestions";
      };

      syntaxHighlighting = {
        enable = mkEnableOption "Enable zsh syntax highlighting";
      };

      ohmyzsh = {
        enable = mkEnableOption "Enable oh-my-zsh";
        theme = mkOption {
          type = types.str;
          default = "robbyrussell";
          description = "oh-my-zsh theme";
        };
        plugins = mkOption {
          type = types.listOf types.str;
          default = [
            "git"
            "docker"
          ];
          description = ''
            oh-my-zsh plugins. Các định nghĩa từ nhiều module được cộng dồn
            (base + profile + file theo OS) và loại trùng khi áp dụng.
          '';
        };
      };

      aliases = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Shell aliases";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra zsh configuration";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.zsh = mkIf cfg.zsh.enable {
      enable = true;
      autosuggestion.enable = cfg.zsh.autosuggestions.enable;
      syntaxHighlighting.enable = cfg.zsh.syntaxHighlighting.enable;
      oh-my-zsh = mkIf cfg.zsh.ohmyzsh.enable {
        enable = true;
        theme = cfg.zsh.ohmyzsh.theme;
        plugins = unique cfg.zsh.ohmyzsh.plugins;
      };

      shellAliases = cfg.zsh.aliases;
      initContent = cfg.zsh.extraConfig;
    };
  };
}
