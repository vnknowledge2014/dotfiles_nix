{ config, lib, pkgs, system, inputs, ... }:

{
  # Import các module
  imports = [
    ../../modules/core
    ../../modules/shell
    ../../modules/dev/git.nix
    ../../modules/editors
  ];

  # Bật các module
  modules = {
    core = {
      enable = true;
      packages = with pkgs; [

      ];
    };
    
    shell = {
      enable = true;
      zsh = {
        enable = true;
        autosuggestions.enable = true;  # Moved outside of oh-my-zsh
        syntaxHighlighting.enable = true;  # Moved outside of oh-my-zsh
        ohmyzsh = {
          enable = true;
          theme = "robbyrussell";
          plugins = [ "git" "macos" "docker" ];  # Removed autosuggestions and syntax-highlighting from here
        };
        aliases = {
          ll = lib.mkForce "eza -l --icons";
          la = lib.mkForce "eza -la --icons";
          cat = lib.mkForce "bat";
          top = lib.mkForce "htop";
          g = lib.mkForce "git";
        };
        extraConfig = ''
          # Enable Starship
          eval "$(starship init zsh)"
          
          # Historry
          HISTSIZE=10000
          SAVEHIST=10000
          
          # Tích hợp FZF
          if [ -n "$(command -v fzf)" ]; then
            source ${pkgs.fzf}/share/fzf/completion.zsh
            source ${pkgs.fzf}/share/fzf/key-bindings.zsh
          fi

          # Auto-start tmux (an toàn)
          if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -n "$PS1" ]; then
            # Chỉ chạy khi không trong tmux và là interactive shell
            source ~/.config/tmux/.tmux.conf
            if tmux has-session 2>/dev/null; then
              # Có session sẵn, attach vào
              tmux attach-session
            else
              # Không có session, tạo mới
              tmux new-session
            fi
          fi
          
          neofetch
          export PATH="''${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
          # export DOCKER_HOST='unix:///var/folders/hf/z_4jqsxs05b28y3_qt8j7tmh0000gn/T/podman/podman-machine-default-api.sock'
          export DOCKER_HOST='unix:///Users/mike/.orbstack/run/docker.sock'

          # Rustup
          source "$HOME/.cargo/env"
          
          # Greeting message
          echo "Welcome to your macOS development environment, Mike!"
          echo "Remember to stay hydrated and take breaks while coding!"
        '';
      };
    };
    
    dev.git = {
      enable = true;
      extraConfig = {
        core.editor = "nvim";
      };
    };
    
    editors = {
      enable = true;
      neovim.enable = true;
    };
  };

  # Các package cá nhân
  home.packages = with pkgs; [

  ];

  # Cấu hình Git cá nhân
  programs.git = {
    userName = "architectureman";
    userEmail = "vnknowledge2014@gmail.com";
  };

   programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };

      directory = {
        truncation_length = 8;
        truncate_to_repo = true;
        style = "bold blue";
      };

      git_branch = {
        symbol = "🌱 ";
        truncation_length = 20;
        truncation_symbol = "";
        style = "bold purple";
      };

      git_commit = {
        commit_hash_length = 8;
        style = "bold green";
      };

      git_state = {
        format = "[\($state( $progress_current of $progress_total)\)]($style) ";
        cherry_pick = "[🍒 PICKING](bold red)";
      };

      git_status = {
        conflicted = "🏳 ";
        ahead = "🏎💨 ";
        behind = "😰 ";
        diverged = "😵 ";
        untracked = "🤷 ";
        stashed = "📦 ";
        modified = "📝 ";
        staged = "[++\($count\)](green)";
        renamed = "👅 ";
        deleted = "🗑 ";
      };

      golang = {
        symbol = "🐹 ";
        style = "bold cyan";
      };

      nodejs = {
        symbol = "⬢ ";
        style = "bold green";
      };

      python = {
        symbol = "🐍 ";
        pyenv_version_name = true;
        style = "bold yellow";
      };

      rust = {
        symbol = "🦀 ";
        style = "bold red";
      };

      nix_shell = {
        symbol = "❄️ ";
        style = "bold blue";
        format = "via [$symbol$state( \($name\))]($style) ";
      };

      time = {
        disabled = false;
        format = "🕙 [$time]($style) ";
        time_format = "%T";
        style = "bright-black";
      };

      cmd_duration = {
        min_time = 500;
        format = "took [$duration](bold yellow)";
      };

      memory_usage = {
        disabled = false;
        threshold = -1;
        symbol = "🧠 ";
        style = "bold dimmed white";
        format = "$symbol[$ram( | $swap)]($style) ";  # Fixed: removed ${} syntax
      };
    };
  };

  # Add tmux configuration
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    keyMode = "vi";
    prefix = "C-a";
    mouse = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "screen-256color";
    extraConfig = ''
      # Unbind default prefix
      unbind C-b
      bind C-a send-prefix

      # Better split commands
      bind | split-window -h
      bind - split-window -v

      # Easy config reload
      bind r source-file ~/.tmux.conf \; display-message "tmux.conf reloaded."

      # Status bar styling
      set -g status-style bg=black,fg=white
      set -g window-status-current-style bg=white,fg=black,bold
    '';
  };

  # Các cấu hình riêng khác
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LANG = "en_US.UTF-8";
    PATH = "$HOME/.cargo/bin:$HOME/.local/bin:$PATH";
  };

  # Đảm bảo thư mục LaunchAgents có quyền truy cập đúng
  home.activation = lib.mkIf (system == "x86_64-darwin" || system == "aarch64-darwin") {
    fixLaunchAgentsPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/Library/LaunchAgents"
      $DRY_RUN_CMD chmod $VERBOSE_ARG 755 "$HOME/Library/LaunchAgents"
    '';
  };

  # Phiên bản Home Manager
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}