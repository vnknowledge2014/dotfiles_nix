{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.terminal;
in {
  options.modules.terminal = {
    enable = mkEnableOption "Enable terminal configuration";
    
    alacritty = {
      enable = mkEnableOption "Enable Alacritty configuration";
      
      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "Alacritty settings";
      };
    };
    
    ghostty = {
      enable = mkEnableOption "Enable Ghostty configuration";
    };

    wezterm = {
      enable = mkEnableOption "Enable WezTerm configuration";
      
      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "WezTerm settings";
      };
    };
  };

  config = mkIf cfg.enable {
    # Alacritty configuration
    programs.alacritty = mkIf cfg.alacritty.enable {
      enable = true;
      settings = cfg.alacritty.settings // {
        # Cấu hình mặc định
        window = {
          padding = {
            x = 10;
            y = 10;
          };
          decorations = "full";
          startup_mode = "Windowed";
        };
        
        font = {
          normal = {
            family = "JetBrains Mono";
            style = "Regular";
          };
          size = 12.0;
        };
        
        # Chủ đề màu mặc định (Nord)
        colors = {
          primary = {
            background = "#2e3440";
            foreground = "#d8dee9";
          };
        };
      };
    };
    
    # Ghostty configuration 
    home.packages = mkIf cfg.ghostty.enable [
      pkgs.ghostty
    ];

    # WezTerm configuration
    programs.wezterm = mkIf cfg.wezterm.enable {
      enable = true;
      extraConfig = ''
        local wezterm = require 'wezterm'
        local config = {}

        -- Default settings
        config.window_padding = {
          left = 10,
          right = 10,
          top = 10,
          bottom = 10
        }

        -- Tương đương với decorations: "full" của Alacritty
        config.window_decorations = "TITLE | RESIZE | MACOS_FORCE_ENABLE_SHADOW"
        
        -- Tương đương với startup_mode: "Windowed" của Alacritty
        config.window_state = "Normal"

        -- Font configuration với style rõ ràng
        config.font = wezterm.font({
          family = "JetBrains Mono",
          weight = "Regular"
        })
        config.font_size = 12.0

        -- Nord theme colors
        config.colors = {
          background = "#2e3440",
          foreground = "#d8dee9"
        }

        -- Additional user settings
        ${concatStringsSep "\n" (mapAttrsToList (name: value: 
          "config.${name} = ${if isString value then ''"${value}"'' else toString value}"
        ) cfg.wezterm.settings)}

        return config
      '';
    };
  };
}