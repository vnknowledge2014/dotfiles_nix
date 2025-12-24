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
        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;
        ohmyzsh = {
          enable = true;
          theme = "robbyrussell";
          plugins = [ "git" "ubuntu" "docker" ];
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
          
          # History
          HISTSIZE=10000
          SAVEHIST=10000
          
          # Tích hợp FZF
          if [ -n "$(command -v fzf)" ]; then
            source ${pkgs.fzf}/share/fzf/completion.zsh
            source ${pkgs.fzf}/share/fzf/key-bindings.zsh
          fi

          # Auto-start tmux (an toàn)
          if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -n "$PS1" ]; then
            source ~/.config/tmux/.tmux.conf
            if tmux has-session 2>/dev/null; then
              tmux attach-session
            else
              tmux new-session
            fi
          fi
          
          neofetch
          export PATH="''${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
          
          # Container runtime detection
          if [[ -S /var/run/docker.sock ]]; then
            export DOCKER_HOST='unix:///var/run/docker.sock'
          elif [[ -S /run/user/$(id -u)/podman/podman.sock ]]; then
            export DOCKER_HOST='unix:///run/user/$(id -u)/podman/podman.sock'
          fi

          # Rustup
          source "$HOME/.cargo/env"

          # Bun and OpenCode
          export PATH="/home/rnd/.bun/bin:$PATH"
          
          # Greeting message
          echo "Welcome to your Ubuntu development environment, RND!"
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
    # Fonts
    nerd-fonts.fira-code
    
    # CLI utilities
    atuin
    yazi
    lazygit
    btop
    eza
    bat
    fzf
    ripgrep
    fd
    jq
    
    # Container tools
    podman
    podman-compose
    podman-tui
    lazydocker
    
    # Kubernetes
    kubectl
    kubernetes-helm
    k9s
    
    # Others
    neofetch
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
        format = "[\\($state( $progress_current of $progress_total)\\)]($style) ";
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
        staged = "[++\\($count\\)](green)";
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
        format = "via [$symbol$state( \\($name\\))]($style) ";
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
        format = "$symbol[$ram( | $swap)]($style) ";
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
    PATH = "$HOME/.cargo/bin:$HOME/.local/bin:/snap/bin:$PATH";
  };

  # Phiên bản Home Manager
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
