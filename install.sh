#!/usr/bin/env bash

set -e

echo "Cài Đặt Dotfiles Đa Nền Tảng"
echo "============================="
echo ""

# Phát hiện hệ điều hành
detect_os() {
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "darwin"
  elif [[ -f /etc/NIXOS ]]; then
    if grep -q "microsoft" /proc/sys/kernel/osrelease 2>/dev/null; then
      echo "nixos-wsl"
    else
      echo "nixos"
    fi
  elif grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    echo "ubuntu"
  else
    echo "unknown"
  fi
}

# Lấy hostname và username
HOSTNAME=${HOSTNAME:-$(hostname -s)}
USERNAME=${USERNAME:-$(whoami)}
OS=$(detect_os)

echo "Hệ thống phát hiện:"
echo "  Hệ điều hành: $OS"
echo "  Hostname: $HOSTNAME"
echo "  Username: $USERNAME"
echo ""

# Xác nhận
read -p "Thông tin đã chính xác? [Y/n] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]; then
  read -p "Nhập hệ điều hành (darwin/nixos/nixos-wsl/ubuntu): " OS
  read -p "Nhập hostname: " HOSTNAME
  read -p "Nhập username: " USERNAME
fi

export HOSTNAME=$HOSTNAME
export USERNAME=$USERNAME

# Kiểm tra profile người dùng
if [[ ! -d "home/profiles/$USERNAME" ]]; then
  echo "Profile cho $USERNAME không tồn tại. Tạo từ template..."
  
  # Tạo thư mục profile
  mkdir -p "home/profiles/$USERNAME"
  cp -r home/profiles/template/* "home/profiles/$USERNAME/"
  
  # Tùy chỉnh thông tin
  read -p "Nhập tên đầy đủ: " FULLNAME
  read -p "Nhập email: " EMAIL
  
  # Cập nhật thông tin
  sed -i "s/Your Name/$FULLNAME/g" "home/profiles/$USERNAME/default.nix"
  sed -i "s/your\.email@example\.com/$EMAIL/g" "home/profiles/$USERNAME/default.nix"
  
  echo "Đã tạo profile cho $USERNAME."
fi

# Thiết lập theo OS
case $OS in
  darwin)
    echo "Thiết lập macOS..."
    
    # Cài đặt Nix nếu chưa có
    if ! command -v nix &> /dev/null; then
      echo "Cài đặt Nix từ Determinate Systems..."
      curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate
      
      # Tải lại environment
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    
    # Cài đặt Homebrew nếu chưa có
    if ! command -v brew &> /dev/null; then
      echo "Cài đặt Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      
      # Thêm Homebrew vào PATH
      if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi
    
    # Cài đặt nix-darwin
    if ! command -v darwin-rebuild &> /dev/null; then
      echo "Cài đặt nix-darwin..."
      nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
      ./result/bin/darwin-installer
      . /etc/static/bashrc
    fi
    
    # Xây dựng cấu hình
    echo "Xây dựng cấu hình Darwin..."
    darwin-rebuild switch --flake .#$HOSTNAME
    ;;
    
  nixos)
    echo "Thiết lập NixOS..."
    
    # Cài đặt Nix từ Determinate Systems nếu chưa có
    if ! command -v nix &> /dev/null; then
      echo "Cài đặt Nix từ Determinate Systems..."
      curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate
      
      # Tải lại environment
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    
    # Kiểm tra cấu hình máy
    if [[ ! -d "hosts/nixos/machines/$HOSTNAME" ]]; then
      echo "Cấu hình cho $HOSTNAME không tồn tại. Tạo từ template..."
      
      # Tạo thư mục cấu hình
      mkdir -p "hosts/nixos/machines/$HOSTNAME"
      
      # Tạo cấu hình phần cứng
      echo "Tạo cấu hình phần cứng..."
      sudo nixos-generate-config --dir "hosts/nixos/machines/$HOSTNAME"
      
      echo "Đã tạo cấu hình cho $HOSTNAME."
    fi
    
    # Xây dựng cấu hình
    echo "Xây dựng cấu hình NixOS..."
    sudo nixos-rebuild switch --flake .#$HOSTNAME
    ;;
    
  nixos-wsl)
    echo "Thiết lập NixOS trên WSL..."
    
    # Đảm bảo flakes được bật
    if ! grep -q "experimental-features" /etc/nix/nix.conf 2>/dev/null; then
      echo "Bật Nix flakes..."
      sudo mkdir -p /etc/nix
      echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
    fi
    
    # Xây dựng cấu hình
    echo "Xây dựng cấu hình NixOS WSL..."
    sudo nixos-rebuild switch --flake .#wsl
    ;;
    
  ubuntu)
    echo "Thiết lập Ubuntu..."
    
    # Cài đặt các gói cần thiết
    echo "Cài đặt các gói cần thiết..."
    sudo apt update
    sudo apt install -y curl git build-essential
    
    # Cài đặt Nix nếu chưa có
    if ! command -v nix &> /dev/null; then
      echo "Cài đặt Nix từ Determinate Systems..."
      curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate
      
      # Tải lại environment
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    
    # Bật flakes
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
    
    # Cài đặt home-manager
    echo "Cài đặt home-manager..."
    nix-shell -p nixFlakes --run "nix run github:nix-community/home-manager/release-24.11 -- switch --flake .#$USERNAME@$HOSTNAME"
    ;;
    
  *)
    echo "Hệ điều hành không được hỗ trợ: $OS"
    exit 1
    ;;
esac

echo ""
echo "Thiết lập hoàn tất! Vui lòng khởi động lại terminal hoặc đăng xuất và đăng nhập lại."