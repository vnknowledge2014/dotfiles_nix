{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.terminal;
in {
  options.modules.terminal = {
    enable = mkEnableOption "Enable terminal configuration";
    
    tmux = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable tmux (enabled by default when terminal module is active)";
      };

      mouse = mkOption {
        type = types.bool;
        default = false;
        description = "Enable mouse support in tmux";
      };
    };

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
    # --- Tmux configuration (full .tmux.conf logic) ---
    programs.tmux = mkIf cfg.tmux.enable {
      enable = true;
      terminal = "screen-256color";
      prefix = "C-a";
      baseIndex = 1;
      keyMode = "vi";
      mouse = cfg.tmux.mouse;
      shell = "${pkgs.zsh}/bin/zsh";

      extraConfig = ''
        # --- Prefix ---
        unbind C-b
        bind-key C-a send-prefix

        # --- Chia panel ---
        # Dọc với \, mở tại thư mục hiện tại
        unbind %
        bind '\' split-window -h -c '#{pane_current_path}'
        # Ngang với -, mở tại thư mục hiện tại
        unbind '"'
        bind - split-window -v -c '#{pane_current_path}'

        # --- Quản lý session, window, pane ---
        bind S command-prompt -p "New Session Name:" "new-session -A -s '%%'"
        bind-key $ command-prompt -I "#S" "rename-session '%%'"
        bind-key , command-prompt -I "#W" "rename-window '%%'"
        bind-key . command-prompt -p "New Pane Name:" -I "#T" "select-pane -T '%%'"
        set-option -g renumber-windows on

        # --- Resize pane: Prefix + Ctrl + h/j/k/l ---
        bind -r C-k resize-pane -U 5
        bind -r C-j resize-pane -D 5
        bind -r C-h resize-pane -L 5
        bind -r C-l resize-pane -R 5
        bind -r m resize-pane -Z

        # --- Copy mode (Vim-style) ---
        set-window-option -g mode-keys vi
        bind-key -T copy-mode-vi 'v' send -X begin-selection
        bind-key -T copy-mode-vi 'y' send -X copy-selection
        unbind -T copy-mode-vi MouseDragEnd1Pane

        # --- Reload cấu hình ---
        unbind r
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded..."

        # --- Status bar (minimal) ---
        set -g status-style fg=default,bg=default
        set -g status-left "#S "
        set -g status-right "%Y-%m-%d %H:%M"
        set -g window-status-current-style "bold"
      '';
    };

    # Alacritty configuration
    programs.alacritty = mkIf cfg.alacritty.enable {
      enable = true;
      settings = cfg.alacritty.settings // {
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

        config.window_padding = {
          left = 10,
          right = 10,
          top = 10,
          bottom = 10
        }

        config.window_decorations = "TITLE | RESIZE | MACOS_FORCE_ENABLE_SHADOW"
        config.window_state = "Normal"

        config.font = wezterm.font({
          family = "JetBrains Mono",
          weight = "Regular"
        })
        config.font_size = 12.0

        config.colors = {
          background = "#2e3440",
          foreground = "#d8dee9"
        }

        ${concatStringsSep "\n" (mapAttrsToList (name: value: 
          "config.${name} = ${if isString value then ''"${value}"'' else toString value}"
        ) cfg.wezterm.settings)}

        return config
      '';
    };
  };
}