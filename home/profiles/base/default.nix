{ config, lib, pkgs, system, ... }:

{
  # Import các module chung
  imports = [
    ../../modules/core
    ../../modules/shell
    ../../modules/dev/git.nix
    ../../modules/editors
    ../../modules/terminal
    ../../modules/secrets.nix
  ];

  # ═══════════════════════════════════════════════════════════
  # MODULE ENABLES — Nguồn duy nhất, mike/rnd chỉ override
  # ═══════════════════════════════════════════════════════════
  modules = {
    core = {
      enable = true;
      packages = with pkgs; [
        curl
        wget
        jq
        ripgrep
        fd
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
          plugins = [ "git" "docker" ]; # Default — profile override thêm "macos"/"ubuntu"
        };
        aliases = {
          ll = "eza -l --icons";
          la = "eza -la --icons";
          cat = "bat";
          top = "htop";
          g = "git";
        };
        extraConfig = ''
          eval "$(starship init zsh)"
          HISTSIZE=10000
          SAVEHIST=10000
          
          if [ -n "$(command -v fzf)" ]; then
            source ${pkgs.fzf}/share/fzf/completion.zsh
            source ${pkgs.fzf}/share/fzf/key-bindings.zsh
          fi

          # Auto-start tmux (an toàn — chạy trên cả macOS và Linux)
          if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -n "$PS1" ]; then
            if tmux has-session 2>/dev/null; then
              tmux attach-session
            else
              tmux new-session
            fi
          fi
          
          neofetch
          export PATH="''${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
          
          # Cargo/Rustup (guard nếu chưa cài)
          [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

          # Bun (guard nếu chưa cài)
          [ -d "$HOME/.bun/bin" ] && export PATH="$HOME/.bun/bin:$PATH"

          # Container runtime auto-detection (Colima trên macOS, Docker Engine trên Linux)
          if [[ -S "$HOME/.colima/default/docker.sock" ]]; then
            export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
          elif [[ -S /var/run/docker.sock ]]; then
            export DOCKER_HOST='unix:///var/run/docker.sock'
          fi
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
      antigravity.enable = true;
    };
    
    secrets.enable = true;
    
    terminal = {
      enable = true;
      tmux = {
        enable = true;
        mouse = true;
      };
      ghostty.enable = true;
    };
  };

  # ═══════════════════════════════════════════════════════════
  # PACKAGES CHUNG — Cài trên tất cả nền tảng
  # ═══════════════════════════════════════════════════════════
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
    gh
    neofetch
    
    # Container tools (cross-platform)
    docker-client
    docker-compose
    docker-credential-helpers
    lazydocker
    
    # Kubernetes
    kubectl
    kubernetes-helm
    k9s
  ]
  # macOS: Colima là container runtime thay OrbStack/Docker Desktop
  ++ lib.optionals pkgs.stdenv.isDarwin [
    colima
  ]
  # Linux: nerdctl cho containerd native
  ++ lib.optionals pkgs.stdenv.isLinux [
    nerdctl
  ];

  # ═══════════════════════════════════════════════════════════
  # STARSHIP — Prompt chung
  # ═══════════════════════════════════════════════════════════
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
        format = "[\\\\($state( $progress_current of $progress_total)\\\\)]($style) ";
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
        staged = "[++\\\\($count\\\\)](green)";
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
        format = "via [$symbol$state( \\\\($name\\\\))]($style) ";
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

  # ═══════════════════════════════════════════════════════════
  # ENVIRONMENT — Session variables chung
  # ═══════════════════════════════════════════════════════════
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LANG = "en_US.UTF-8";
    PATH = "$HOME/.cargo/bin:$HOME/.local/bin:$PATH";
  };

  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
