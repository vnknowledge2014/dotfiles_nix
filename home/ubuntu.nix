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
        ohmyzsh = {
          enable = true;
          theme = "robbyrussell";
          plugins = [ "git" "ubuntu" "docker" ];
        };
        aliases = {
          ll = "ls -l";
          la = "ls -la";
        };
      };
    };
    
    dev.git.enable = true;
    editors.enable = true;
  };
  
  # Các gói cơ bản cho Ubuntu
  home.packages = with pkgs; [

  ];

  # Cấu hình Editor
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    extensions = with pkgs.vscode-extensions; [
      ms-vscode.cpptools
      ms-python.python
    ];
  };
  
  # Tích hợp với snapd
  home.activation.snapPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v snap > /dev/null 2>&1; then
      echo "Cài đặt các gói snap..."
      
      # Danh sách các gói snap
      PACKAGES=(${lib.concatStringsSep " " (map (x: "\"${x}\"") (["code" "spotify" "slack"] ++ (config.extraSnaps or [])))})
      
      for pkg in "''${PACKAGES[@]}"; do
        if ! snap list | grep -q "^$pkg"; then
          echo "Đang cài đặt $pkg..."
          sudo snap install $pkg
        fi
      done
    fi
  '';
  
  # Cấu hình các gói Ubuntu bổ sung
  home.activation.aptPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v apt &>/dev/null; then
      echo "Kiểm tra các gói Ubuntu cơ bản..."
      
      # Danh sách các gói apt cần thiết
      APT_PACKAGES=(
        "build-essential"
        "curl"
        "git"
        "zsh"
      )
      
      for pkg in "''${APT_PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg"; then
          echo "Đang cài đặt $pkg..."
          sudo apt update
          sudo apt install -y $pkg
        fi
      done
    fi
  '';
  
  # Phiên bản Home Manager
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}