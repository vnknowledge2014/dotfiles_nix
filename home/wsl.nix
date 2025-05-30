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
  home.username = username;
  home.homeDirectory = "/home/${username}";
  
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
          plugins = [ "git" "wsl" "docker" ];
        };
        aliases = {
          ll = "ls -l";
          la = "ls -la";
          explorer = "explorer.exe";
          code = "code.exe";
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
    wsl-open  # Mở file Windows từ WSL
    wsl-clipboard  # Tích hợp clipboard
  ];

  # Tích hợp Windows
  programs.zsh.initContent = lib.mkIf config.programs.zsh.enable ''
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
  
  # Tích hợp VSCode giữa WSL và Windows
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      ms-vscode-remote.remote-wsl
    ];
  };
  
  # Cấu hình cho Git để làm việc tốt hơn với Windows
  programs.git.extraConfig = {
    core.autocrlf = "input";
    core.eol = "lf";
  };
  
  # Phiên bản Home Manager
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}