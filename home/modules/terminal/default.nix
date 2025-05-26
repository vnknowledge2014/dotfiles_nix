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
  };
}