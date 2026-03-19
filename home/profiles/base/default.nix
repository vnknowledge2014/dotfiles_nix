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

  # Bật các module mặc định
  modules = {
    core.enable = true;
    
    shell = {
      enable = true;
      zsh = {
        enable = true;
        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;
        ohmyzsh = {
          enable = true;
          theme = "robbyrussell";
          plugins = [ "git" "docker" "ubuntu" ]; # Default plugins
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
          
          source "$HOME/.cargo/env"
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

  # Packages cơ bản
  home.packages = with pkgs; [
    # Common tools
  ];

  # Starship configuration
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

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LANG = "en_US.UTF-8";
    PATH = "$HOME/.cargo/bin:$HOME/.local/bin:$PATH";
  };

  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
