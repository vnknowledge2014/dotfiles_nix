{ config, lib, pkgs, system, inputs, hostname, username, ... }:

{
  # Import các module cơ bản
  imports = [ 
    ./modules/core
    ./modules/shell
    ./modules/dev/git.nix
    ./modules/editors
    ./profiles/${username}
  ];
  
  # Thông tin cơ bản
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
  };
  
  # Kích hoạt các module cơ bản
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
          plugins = [ "git" "wsl" ];
        };
        aliases = {
          ll = lib.mkForce "ls -l";
          la = lib.mkForce "ls -la";
          pbcopy = "wsl-pbcopy";
          pbpaste = "wsl-pbpaste";
          open = "wslview";
          explorer = "explorer.exe";
        };
      };
    };
    
    dev.git.enable = true;
    editors.enable = true;
  };
  
  # Các gói cơ bản cho WSL
  home.packages = with pkgs; [
    # CLI tools
    wslu  # Tiện ích WSL
    # wsl-open  # Mở file Windows từ WSL (thay bằng wslview từ wslu)
    # wsl-clipboard
  ];

  programs = {
    home-manager.enable = true;
    zsh.initContent = lib.mkIf config.programs.zsh.enable ''
      # Cấu hình PATH cho WSL2
      export PATH="$HOME/.local/bin:$PATH"
      
      # Fix permissions cảnh báo của zsh compinit
      if [[ -d /usr/share/zsh/site-functions ]]; then
        chmod -f g-w,o-w /usr/share/zsh/site-functions || true
      fi

      # Đường dẫn Windows
      export PATH=$PATH:/mnt/c/Windows/System32:/mnt/c/Windows
      
      # Tích hợp WSL
      export BROWSER="wslview"
      
      # Tự động chuyển đến thư mục Windows home khi mở terminal
      if [ -d "/mnt/c/Users/$USER" ]; then
        WINDOWS_HOME="/mnt/c/Users/$USER"
        if [ "$PWD" = "$HOME" ]; then
          cd "$WINDOWS_HOME"
        fi
      fi
    '';
    git.extraConfig = {
      core.autocrlf = "input";
      core.eol = "lf";
    };
  };
}