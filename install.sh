#!/usr/bin/env bash

set -e

# Kiểm tra đang chạy từ thư mục đúng
if [[ ! -f "flake.nix" ]]; then
  echo "Lỗi: Script phải được chạy từ thư mục gốc của dotfiles (chứa file flake.nix)"
  echo "Hướng dẫn:"
  echo "  cd /path/to/dotfiles"
  echo "  ./install.sh"
  exit 1
fi

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
  
  # Cập nhật thông tin (sử dụng cú pháp tương thích với macOS)
  if [[ "$OS" == "darwin" ]]; then
    sed -i '' "s/Your Name/$FULLNAME/g" "home/profiles/$USERNAME/default.nix"
    sed -i '' "s/your\.email@example\.com/$EMAIL/g" "home/profiles/$USERNAME/default.nix"
  else
    sed -i "s/Your Name/$FULLNAME/g" "home/profiles/$USERNAME/default.nix"
    sed -i "s/your\.email@example\.com/$EMAIL/g" "home/profiles/$USERNAME/default.nix"
  fi
  
  echo "Đã tạo profile cho $USERNAME."
fi

# Thiết lập theo OS
case $OS in
  darwin)
    echo "Thiết lập macOS..."
    
    # Cài đặt Nix nếu chưa có
    if ! command -v nix &> /dev/null; then
      echo "Cài đặt Nix..."
      sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
      
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
      echo "Setup Xcode license accept"
      sudo xcodebuild -license accept

      # Backup existing /etc files that nix-darwin will manage
      echo "Backing up existing /etc files..."
      if [[ -f /etc/zshrc ]]; then
        sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
        echo "Backed up /etc/zshrc to /etc/zshrc.before-nix-darwin"
      fi
      if [[ -f /etc/zprofile ]]; then
        sudo mv /etc/zprofile /etc/zprofile.before-nix-darwin
        echo "Backed up /etc/zprofile to /etc/zprofile.before-nix-darwin"
      fi
      if [[ -f /etc/bashrc ]]; then
        sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
        echo "Backed up /etc/bashrc to /etc/bashrc.before-nix-darwin"
      fi

      echo "Cài đặt nix-darwin..."
      sudo nix run nix-darwin -- switch --flake .#$HOSTNAME

      # Tải lại PATH sau khi cài đặt nix-darwin
      if [[ -f /etc/static/bashrc ]]; then
        source /etc/static/bashrc
      fi
    fi
    
    # Kiểm tra cấu hình máy tồn tại
    if [[ ! -d "hosts/darwin/machines/$HOSTNAME" ]]; then
      echo "Cảnh báo: Không tìm thấy cấu hình cho máy $HOSTNAME"
      echo "Tạo cấu hình từ template..."
      mkdir -p "hosts/darwin/machines/$HOSTNAME"
      cp "hosts/darwin/machines/template/default.nix" "hosts/darwin/machines/$HOSTNAME/default.nix"
      echo "Đã tạo cấu hình cho $HOSTNAME từ template"
    fi

    # Xây dựng cấu hình
    echo "Xây dựng cấu hình Darwin..."
    if sudo darwin-rebuild switch --flake .#$HOSTNAME; then
      echo "Xây dựng cấu hình Darwin thành công"
    else
      echo "Lỗi: Không thể xây dựng cấu hình Darwin. Vui lòng kiểm tra lại cấu hình."
      exit 1
    fi

    echo "Cài đặt các ngôn ngữ lập trình trên asdf"
    if [[ -f "./asdf-vm/planguage.sh" ]]; then
      chmod +x ./asdf-vm/planguage.sh
      bash ./asdf-vm/planguage.sh
    else
      echo "Cảnh báo: Không tìm thấy file asdf-vm/planguage.sh"
    fi

    echo "Cài đặt tmux"
    if [[ -f "./ghostty-tmux/.tmux.conf" ]]; then
      mkdir -p ~/.config/tmux
      cp ./ghostty-tmux/.tmux.conf ~/.config/tmux/.tmux.conf
      echo "Đã cài đặt cấu hình tmux"
    else
      echo "Cảnh báo: Không tìm thấy file ghostty-tmux/.tmux.conf"
    fi
    ;;
    
  nixos)
    echo "Thiết lập Nix | NixOS..."
    
    # Cài đặt Nix từ Nix nếu chưa có
    if ! command -v nix &> /dev/null; then
      echo "Cài đặt Nix..."
      sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
      
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
    
    # Kiểm tra Nix đã được cài đặt chưa (kiểm tra thư mục /nix)
    if [[ -d "/nix" && -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
      echo "Nix đã được cài đặt, bỏ qua bước cài đặt Nix"
      # Tải lại environment
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    else
      echo "Cài đặt Nix..."
      sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
      
      # Tải lại environment
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    
    # Bật flakes
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
    
    # Cài đặt home-manager
    echo "Cài đặt home-manager..."
    if nix run github:nix-community/home-manager/release-25.05 -- switch --flake .#$USERNAME@$HOSTNAME; then
      echo "Cài đặt home-manager thành công"
    else
      echo "Lỗi: Không thể cài đặt home-manager. Thử lại với nix-shell..."
      nix-shell -p nixFlakes --run "nix run github:nix-community/home-manager/release-25.05 -- switch --flake .#$USERNAME@$HOSTNAME"
    fi
    ;;
    
  *)
    echo "Hệ điều hành không được hỗ trợ: $OS"
    exit 1
    ;;
esac

echo ""
echo "Thiết lập hoàn tất! Vui lòng khởi động lại terminal hoặc đăng xuất và đăng nhập lại."
