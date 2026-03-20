{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.modules.terminal;
  clipboardCmd = if pkgs.stdenv.isDarwin then "pbcopy" else "xclip -in -selection clipboard";
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
      
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra Ghostty configuration lines";
      };
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
        bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "${clipboardCmd}"
        bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "${clipboardCmd}"

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
    xdg.configFile."ghostty/config" = mkIf cfg.ghostty.enable {
      text = ''
        # Theme
        theme = Catppuccin Macchiato
        font-family = Cascadia Mono NF
        font-synthetic-style = false
        font-size = 12

        # Window
        window-height = 45
        window-width = 180
        window-padding-x = 8
        window-padding-y = 8
        window-padding-balance = true
        window-save-state = never
        window-new-tab-position = current

        # Cursor
        cursor-style = block
        cursor-style-blink = false
        shell-integration-features = no-cursor

        # Quick Terminal
        quick-terminal-position = center
        quick-terminal-animation-duration = 0
        quick-terminal-size = 70%,70%

        # Notifications
        notify-on-command-finish = unfocused
        notify-on-command-finish-action = notify
        notify-on-command-finish-after = 10s

        # Misc
        copy-on-select = clipboard
        confirm-close-surface = true
        macos-option-as-alt = true
        clipboard-paste-protection = false
        clipboard-paste-bracketed-safe = true
        auto-update-channel = stable

        # Keybindings
        keybind = clear

        keybind = super+n=new_window
        keybind = super+q=quit
        keybind = super+w=close_surface
        keybind = super+shift+w=close_window
        keybind = super+ctrl+f=toggle_fullscreen

        keybind = super+t=new_tab
        keybind = super+alt+right=next_tab
        keybind = super+alt+left=previous_tab

        keybind = super+physical:one=goto_tab:1
        keybind = super+physical:two=goto_tab:2
        keybind = super+physical:three=goto_tab:3
        keybind = super+physical:four=goto_tab:4
        keybind = super+physical:five=goto_tab:5
        keybind = super+physical:six=goto_tab:6
        keybind = super+physical:seven=goto_tab:7
        keybind = super+physical:eight=goto_tab:8
        keybind = super+physical:nine=goto_tab:9

        keybind = super+d=new_split:right
        keybind = super+shift+d=new_split:down
        keybind = super+shift+enter=toggle_split_zoom

        keybind = super+ctrl+left=goto_split:left
        keybind = super+ctrl+right=goto_split:right
        keybind = super+ctrl+up=goto_split:top
        keybind = super+ctrl+down=goto_split:bottom

        keybind = super+ctrl+alt+left=resize_split:left,10
        keybind = super+ctrl+alt+right=resize_split:right,10
        keybind = super+ctrl+alt+up=resize_split:up,10
        keybind = super+ctrl+alt+down=resize_split:down,10

        keybind = super+home=scroll_to_top
        keybind = super+end=scroll_to_bottom
        keybind = super+page_up=scroll_page_up
        keybind = super+page_down=scroll_page_down

        keybind = super+plus=increase_font_size:1
        keybind = super+equal=increase_font_size:1
        keybind = super+minus=decrease_font_size:1
        keybind = super+zero=reset_font_size

        keybind = super+v=paste_from_clipboard
        keybind = super+c=copy_to_clipboard
        keybind = super+a=select_all
        keybind = super+k=clear_screen
        keybind = super+p=toggle_command_palette
        keybind = super+f=write_screen_file:open

        keybind = super+shift+left=adjust_selection:left
        keybind = super+shift+right=adjust_selection:right
        keybind = super+shift+up=adjust_selection:up
        keybind = super+shift+down=adjust_selection:down
        keybind = super+shift+page_up=adjust_selection:page_up
        keybind = super+shift+page_down=adjust_selection:page_down
        keybind = super+shift+end=adjust_selection:end
        keybind = super+shift+home=adjust_selection:home

        keybind = global:super+#=toggle_quick_terminal
        keybind = global:super+'=toggle_quick_terminal

        ${cfg.ghostty.extraConfig}
      '';
    };

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