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
  
  # Packages được định nghĩa trong profile
  
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
      SNAP_PACKAGES="spotify ghostty"
      SNAP_CLASSIC="ghostty"
      
      for pkg in $SNAP_PACKAGES; do
        if ! $SNAP_CMD list 2>/dev/null | grep -q "^$pkg "; then
          echo "Đang cài đặt $pkg..."
          
          if echo "$SNAP_CLASSIC" | grep -q "$pkg"; then
            if $SNAP_CMD install $pkg --classic 2>&1; then
              echo "✓ Đã cài đặt $pkg"
            else
              echo "✗ Lỗi khi cài đặt $pkg"
            fi
          else
            if $SNAP_CMD install $pkg 2>&1; then
              echo "✓ Đã cài đặt $pkg"
            else
              echo "✗ Lỗi khi cài đặt $pkg"
            fi
          fi
        else
          echo "✓ $pkg đã được cài đặt"
        fi
      done
    else
      echo "Snap không khả dụng trên hệ thống này"
    fi
  '';
  
  # Tích hợp với Flatpak
  home.activation.flatpakPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -x /usr/bin/flatpak ]]; then
      echo "Cài đặt các gói flatpak..."
      
      if ! /usr/bin/flatpak list | grep -q "io.podman_desktop.PodmanDesktop" 2>/dev/null; then
        echo "Đang cài đặt Podman Desktop..."
        /usr/bin/flatpak install -y flathub io.podman_desktop.PodmanDesktop
        echo "✓ Đã cài đặt Podman Desktop"
      else
        echo "✓ Podman Desktop đã được cài đặt"
      fi
    else
      echo "Flatpak không khả dụng, bỏ qua cài đặt Podman Desktop"
    fi
  '';
  
  # Cấu hình Docker repository
  home.activation.dockerSetup = lib.hm.dag.entryBefore ["writeBoundary"] ''
    if ! command -v docker &> /dev/null; then
      echo "Thiết lập Docker repository..."
      
      # Add Docker's official GPG key
      /usr/bin/sudo /usr/bin/install -m 0755 -d /etc/apt/keyrings
      /usr/bin/curl -fsSL https://download.docker.com/linux/ubuntu/gpg | /usr/bin/sudo /usr/bin/gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
      /usr/bin/sudo /usr/bin/chmod a+r /etc/apt/keyrings/docker.gpg
      
      # Add repository
      echo \
        "deb [arch=$(/usr/bin/dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        /usr/bin/sudo /usr/bin/tee /etc/apt/sources.list.d/docker.list > /dev/null
      
      /usr/bin/sudo /usr/bin/apt update
    fi
  '';
  
  # Cấu hình các gói Ubuntu bổ sung
  home.activation.aptPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v apt &>/dev/null; then
      echo "Kiểm tra Docker packages..."
      
      # Danh sách các gói Docker
      DOCKER_PACKAGES=(
        "docker-ce"
        "docker-ce-cli"
        "containerd.io"
        "docker-buildx-plugin"
        "docker-compose-plugin"
      )
      
      MISSING_PACKAGES=()
      for pkg in "''${DOCKER_PACKAGES[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null 2>&1; then
          MISSING_PACKAGES+=("$pkg")
        fi
      done
      
      if [ ''${#MISSING_PACKAGES[@]} -gt 0 ]; then
        echo "Cài đặt Docker packages: ''${MISSING_PACKAGES[*]}"
        /usr/bin/sudo apt install -y "''${MISSING_PACKAGES[@]}"
        echo "✓ Đã cài đặt Docker packages"
      fi
      
      # Add user to docker group
      if command -v docker &> /dev/null; then
        if ! groups | grep -q docker; then
          echo "Thêm user vào docker group..."
          /usr/bin/sudo usermod -aG docker $USER
          echo "⚠️  Vui lòng logout và login lại để áp dụng docker group."
        fi
      fi
    fi
  '';
  
  # Phiên bản Home Manager
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}