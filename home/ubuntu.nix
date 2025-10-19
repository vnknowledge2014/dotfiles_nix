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
  
  # Tích hợp với snapd
  home.activation.snapPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Kiểm tra snap bằng cách tìm file thực thi
    SNAP_CMD=""
    if [[ -x /usr/bin/snap ]]; then
      SNAP_CMD="/usr/bin/snap"
    elif [[ -x /snap/bin/snap ]]; then
      SNAP_CMD="/snap/bin/snap"
    elif command -v snap > /dev/null 2>&1; then
      SNAP_CMD="snap"
    fi
    
    if [[ -n "$SNAP_CMD" ]]; then
      echo "Cài đặt các gói snap..."
      
      # Danh sách snap packages
      SNAP_PACKAGES="code spotify slack"
      
      for pkg in $SNAP_PACKAGES; do
        if ! $SNAP_CMD list 2>/dev/null | grep -q "^$pkg "; then
          echo "Đang cài đặt $pkg..."
          if $SNAP_CMD install $pkg 2>&1; then
            echo "✓ Đã cài đặt $pkg"
          else
            echo "✗ Lỗi khi cài đặt $pkg"
          fi
        else
          echo "✓ $pkg đã được cài đặt"
        fi
      done
    else
      echo "Snap không khả dụng trên hệ thống này"
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
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}