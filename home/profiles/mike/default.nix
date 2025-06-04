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
          
          # Greeting message
          neofetch
          export PATH="''${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
          export DOCKER_HOST='unix:///var/folders/hf/z_4jqsxs05b28y3_qt8j7tmh0000gn/T/podman/podman-machine-default-api.sock'
          echo "Welcome to your macOS development environment, Mike!"
        '';
      };
    };
    
    dev.git = {
      enable = true;
      extraConfig = {
        core.editor = "code --wait";
      };
    };
    
    editors = {
      enable = true;
      neovim.enable = true;
      vscode.enable = true;
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

  # Cấu hình Editor
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      # Your additional personal extensions here
      github.copilot-chat
      github.copilot
      rust-lang.rust-analyzer
      pkief.material-icon-theme
      aaron-bond.better-comments
      bradlc.vscode-tailwindcss
      esbenp.prettier-vscode
      formulahendry.code-runner
      denoland.vscode-deno
      golang.go
      vlanguage.vscode-vlang
      ziglang.vscode-zig
      jnoortheen.nix-ide
      gleam.gleam
      haskell.haskell
      ocamllabs.ocaml-platform
      dart-code.flutter
      dart-code.dart-code
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "vscode-yaml";
        publisher = "redhat";
        version = "1.18.0";
        sha256 = "sha256-UtxDplORUWqmiW6I8n4ZhK7HAQdSDG4dw7M/cbjkmZY=";
      }
      {
        name = "drone-ci";
        publisher = "maximtrp";
        version = "2.0.1";
        sha256 = "sha256-sw8lYcJqz6mvDeGXDiC2+SZn3WW7K4bHQ7P1N6Lq0uQ=";
      }
      {
        name = "vscode-tekton-pipelines";
        publisher = "redhat";
        version = "1.1.0";
        sha256 = "sha256-HBjBX+nX8C4wTFgFtcRbbeyCwp0bLkVtetjw+k1zbkc=";
      }
      {
        name = "vscode-thunder-client";
        publisher = "rangav";
        version = "2.35.0";
        sha256 = "sha256-K0zsgtX1lZptLbeNBA6kFTdNhNWDwtwGfs/4kAHvNW8=";
      }
      {
        name = "synthwave-vscode";
        publisher = "RobbOwen";
        version = "0.1.19";
        sha256 = "sha256-Og1ZBmZO1x0vyhpK+D5ODOBo57vEyBxk5lqJemh+0lE=";
      }
      {
        name = "vscode-codemetrics";
        publisher = "kisstkondoros";
        version = "1.26.1";
        sha256 = "sha256-lw6eZwlMXEjaT+FhhmiLkCB49Q7C015vU7zOLLTtGf8=";
      }
      {
        name = "luahelper";
        publisher = "yinfei";
        version = "0.2.29";
        sha256 = "sha256-/2RTIl3avuQb0DRciUwDYyJ/vfHjtGWyxSuB8ssYZuo=";
      }
      {
        name = "ide-purescript";
        publisher = "nwolverson";
        version = "0.26.6";
        sha256 = "sha256-zYLAcPgvfouMQj3NJlNJA0DNeayKxQhOYNloRN2YuU8=";
      }
      {
        name = "elixir-ls";
        publisher = "JakeBecker";
        version = "0.28.0";
        sha256 = "sha256-pHLAA7i2HJC523lPotUy5Zwa3BTSTurC2BA+eevdH38=";
      }
      {
        name = "erlang-ls";
        publisher = "erlang-ls";
        version = "0.0.46";
        sha256 = "sha256-HvQ0qv1wA+qSN1+8r9Z4iTq7DtpsCvOZ73bACeHZ9+o=";
      }
      {
        name = "debugpy";
        publisher = "ms-python";
        version = "2025.9.2025052001";
        sha256 = "sha256-q+rYLsOj81VISjGB0iAkC+8Rh4EaJvohLw6SfPptnJM=";
      }
      {
        name = "python";
        publisher = "ms-python";
        version = "2025.7.2025052901";
        sha256 = "sha256-hZZqSDlHdBvvHcA24NZ23X0xgKd2RAyc1xLJagnd4T0=";
      }
      {
        name = "vscode-fp-ts-codegen";
        publisher = "betafcc";
        version = "1.0.0";
        sha256 = "sha256-8dWD1O05ytmcpsI7m2zge8DUE8oymdqnqVHqflRNono=";
      }
      {
        name = "fp-ts-import";
        publisher = "ooga";
        version = "1.2.2";
        sha256 = "sha256-/5PeFmnk1eCDWvwCBK1iz/Q/zISQlltHOZlhnEoooFo=";
      }
      {
        name = "fp-ts-snippets";
        publisher = "juan-ojeda-dev";
        version = "2.1.2";
        sha256 = "sha256-CWQomrXn4BaruGxMRas0XE6EHW2qw5JBsuqiSOFkJJ8=";
      }
      {
        name = "effect-vscode";
        publisher = "effectful-tech";
        version = "0.1.7";
        sha256 = "sha256-qLTqOxQCTIn/tzbTU51D/XpOYnPn1M1/8UNv30t9hDE=";
      }
      {
        name = "oracle-java";
        publisher = "Oracle";
        version = "24.0.0";
        sha256 = "sha256-sw+FJbpdkHABKgnRsA5tS6FYEjBD0/iVRCHHzf49Xx4=";
      }
      {
        name = "cpptools";
        publisher = "ms-vscode";
        version = "1.26.1";
        sha256 = "sha256-uVE7sEO8XN3ArFpElUw25/BKyCOzF1EmZ5nHBkdoL/0=";
      }
      {
        name = "explorer";
        publisher = "vitest";
        version = "1.18.1";
        sha256 = "sha256-M/eC7nmFj3BQGlx9J2kqLAKObPYhAit7hVdKYuQlfKw=";
      }
      {
        name = "stately-vscode";
        publisher = "statelyai";
        version = "2.1.0";
        sha256 = "sha256-ZTbdFDN/5HpwQiPAnFcYQ9o+2+Rx/akflP9tjkmG3Jg=";
      }
      {
        name = "sass-indented";
        publisher = "Syler";
        version = "1.8.33";
        sha256 = "sha256-7+Yo6X+t56tnZzepBKEo5hJdgLxiF3+83hSFqpkhVpA=";
      }
      {
        name = "vscode-react-native";
        publisher = "msjsdiag";
        version = "1.13.0";
        sha256 = "sha256-zryzoO9sb1+Kszwup5EhnN/YDmAPz7TOQW9I/K28Fmg=";
      }
      {
        name = "es7-react-js-snippets";
        publisher = "dsznajder";
        version = "4.4.3";
        sha256 = "sha256-QF950JhvVIathAygva3wwUOzBLjBm7HE3Sgcp7f20Pc="; 
      }
      {
        name = "mui-snippets";
        publisher = "vscodeshift";
        version = "1.0.1";
        sha256 = "sha256-JsZTFI2dutZ9bA2nLBaSC/cXTXj+ZuSxgiWr6MqWLYc="; 
      }
      {
        name = "vscode-kubernetes-tools";
        publisher = "ms-kubernetes-tools";
        version = "1.3.23";
        sha256 = "sha256-8s1fuuTwUPd1Z32EqZNloD50KaFlPOxlvMmo5D6NaE4=";
      }
      {
        name = "kind-vscode";
        publisher = "ms-kubernetes-tools";
        version = "0.0.3";
        sha256 = "sha256-GrckW8n3ccLn2r+cEUoe1hr51th9ZDsFlwkRP2OVMGk=";
      }  
      {
        name = "vscode-knative";
        publisher = "redhat";
        version = "1.5.0";
        sha256 = "sha256-k6+siH9wtgJ89ZF4dilkvdfnfH9q/rUI9CZ5/uzsl+U=";
      }
      {
        name = "ansible";
        publisher = "redhat";
        version = "25.4.0";
        sha256 = "sha256-E/BogNtax4dkv6hlYcaRinTxr4jnVyV9hVCdkIkul9s=";
      }
      {
        name = "vscode-qwik-snippets";
        publisher = "johnreemar";
        version = "1.2.6";
        sha256 = "sha256-U4V+hXtDp7ll64k0wHxnBHszoMlK3BXBwaMf/snIics=";
      }
      {
        name = "opentofu";
        publisher = "gamunu";
        version = "0.2.1";
        sha256 = "sha256-OizdHTSGuwBRuD/qPXjmna6kZWfRp9EimhcFk3ICN9I=";
      }
      {
        name = "aws-toolkit-vscode";
        publisher = "AmazonWebServices";
        version = "2.2.0";
        sha256 = "sha256-BozINc0qBMJpRW8KnqiejFtQIE2v4E49mTYyv4F/MCQ="; 
      }
      {
        name = "amazon-q-vscode";  # Changed from Bun-for-Visual-Studio-Code
        publisher = "Amazonwebservices";
        version = "1.70.0";
        sha256 = "sha256-nMAhVl93CImy0tQ6naB2tBAcMVC6Elo2AfvQj3jaEc4=";

      }
      {
        name = "bun-vscode";
        publisher = "oven";
        version = "0.0.28";
        sha256 = "sha256-WlGqqKbfrV0gqCCdVo/UFF+Gnxhq0TNJ4LuHwFaFYXA=";
      }
      {
        name = "vscode-containers";
        publisher = "ms-azuretools";
        version = "2.0.2";
        sha256 = "sha256-xdQdQraCQ5FByHHZjdyE1z0zEqZcJAJAi/t3OGVtbWU=";
      }
    ] ++ (config.modules.editors.vscode.extensions or []); # Merge with base extensions

    userSettings = lib.recursiveUpdate 
      (config.modules.editors.vscode.userSettings or {})
      {
        # Your additional personal settings here
        # These will be merged with the base settings
        "aws.samcli.lambdaTimeout" = 91234;
        "editor.fontSize" = 14;
        "github.copilot.nextEditSuggestions.enabled" = true;
        "editor.largeFileOptimizations" = true;
        "editor.fontFamily" = "FiraCode Nerd Font";
        "terminal.integrated.fontFamily" = "FiraCode Nerd Font Mono";
        "editor.fontLigatures" = true;
        # Add more personal settings...
      };

    keybindings = [
      {
        key = "cmd+shift+[";
        command = "workbench.action.previousEditor";
      }
      {
        key = "cmd+shift+]";
        command = "workbench.action.nextEditor";
      }
      {
        key = "cmd+w";
        command = "workbench.action.closeActiveEditor";
      }
      # Add more keybindings as needed...
    ] ++ (config.modules.editors.vscode.keybindings or []); # Merge with base keybindings
  };

  # Các cấu hình riêng khác
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "code";
    LANG = "en_US.UTF-8";
    PATH = "$HOME/.local/bin:$PATH";
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