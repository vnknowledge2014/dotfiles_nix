#!/usr/bin/env bash

set -e

# ============================================================================
# Dotfiles Đa Nền Tảng — Bootstrap & Install Script
# ============================================================================
# Vai trò:
#   1. Bootstrap: Cài Nix, Homebrew, nix-darwin (nếu chưa có)
#   2. Rebuild:   Gọi darwin-rebuild / nixos-rebuild / home-manager switch
#   3. ASDF:      Cài ngôn ngữ lập trình qua asdf (với preset system)
#   4. Extras:    Các tool mà Nix không quản lý được (Docker APT, Snap, Flatpak, .deb, .dmg)
#
# Mọi config (tmux, shell, editor, starship, ...) được Nix/Home Manager quản lý.
# Script này KHÔNG copy config files — chỉ bootstrap và cài tool ngoài Nix.
# ============================================================================

# Preset và Extra Languages (từ command line)
LANG_PRESET=""
EXTRA_LANGS=""
INTERACTIVE_MODE=false

# Hàm hiển thị menu chọn preset
show_preset_menu() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║           CHỌN PRESET NGÔN NGỮ LẬP TRÌNH                  ║"
  echo "╠═══════════════════════════════════════════════════════════╣"
  echo "║  1. minimal            - Chỉ Python cơ bản                ║"
  echo "║  2. web-developer      - Node.js, Bun, Deno, Python       ║"
  echo "║  3. data-scientist     - Python, UV, Julia                ║"
  echo "║  4. devops-engineer    - Python, Go, Node.js              ║"
  echo "║  5. mobile-developer   - Flutter, Node.js                 ║"
  echo "║  6. systems-developer  - Zig, Go, Rust                    ║"
  echo "║  7. functional-dev     - Haskell, OCaml, Elixir, Gleam    ║"
  echo "║  8. all                - Tất cả ngôn ngữ                  ║"
  echo "║  0. Bỏ qua (không cài ngôn ngữ qua asdf)                  ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo ""
  read -p "Chọn preset (0-8): " choice
  
  case $choice in
    1) LANG_PRESET="minimal" ;;
    2) LANG_PRESET="web-developer" ;;
    3) LANG_PRESET="data-scientist" ;;
    4) LANG_PRESET="devops-engineer" ;;
    5) LANG_PRESET="mobile-developer" ;;
    6) LANG_PRESET="systems-developer" ;;
    7) LANG_PRESET="functional-developer" ;;
    8) LANG_PRESET="all" ;;
    0) LANG_PRESET="" ;;
    *) 
      echo "Lựa chọn không hợp lệ, sử dụng mặc định (all)"
      LANG_PRESET="all"
      ;;
  esac
  
  if [[ -n "$LANG_PRESET" ]]; then
    echo ""
    read -p "Thêm ngôn ngữ ngoài preset? (ví dụ: rust,java) [Enter để bỏ qua]: " EXTRA_LANGS
  fi
  
  echo ""
  echo "Preset đã chọn: ${LANG_PRESET:-"(không cài)"}"
  [[ -n "$EXTRA_LANGS" ]] && echo "Ngôn ngữ thêm: $EXTRA_LANGS"
  echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --preset)
      LANG_PRESET="$2"
      shift 2
      ;;
    --add)
      EXTRA_LANGS="$2"
      shift 2
      ;;
    --interactive|-i)
      INTERACTIVE_MODE=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --preset PRESET  Chọn preset ngôn ngữ lập trình"
      echo "                   (minimal, web-developer, data-scientist, all, ...)"
      echo "  --add LANGS      Thêm ngôn ngữ ngoài preset (cách nhau bởi dấu phẩy)"
      echo "  --interactive    Chế độ tương tác, hiển thị menu chọn preset"
      echo "  --help           Hiển thị hướng dẫn này"
      echo ""
      echo "Ví dụ:"
      echo "  $0 --preset web-developer"
      echo "  $0 --preset minimal --add rust,go"
      echo "  $0 --interactive"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

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

# Nếu chế độ interactive → hiện menu chọn preset
if [[ "$INTERACTIVE_MODE" == true ]]; then
  show_preset_menu
fi

# ============================================================================
# PHÁT HIỆN HỆ THỐNG
# ============================================================================

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

# ============================================================================
# TẠO USER PROFILE (nếu chưa có)
# ============================================================================

if [[ ! -d "home/profiles/$USERNAME" ]]; then
  echo "Profile cho $USERNAME không tồn tại. Tạo từ template..."
  
  mkdir -p "home/profiles/$USERNAME"
  cp -r home/profiles/template/* "home/profiles/$USERNAME/"
  
  read -p "Nhập tên đầy đủ: " FULLNAME
  read -p "Nhập email: " EMAIL
  
  if [[ "$OS" == "darwin" ]]; then
    sed -i '' "s/Your Name/$FULLNAME/g" "home/profiles/$USERNAME/default.nix"
    sed -i '' "s/your\.email@example\.com/$EMAIL/g" "home/profiles/$USERNAME/default.nix"
  else
    sed -i "s/Your Name/$FULLNAME/g" "home/profiles/$USERNAME/default.nix"
    sed -i "s/your\.email@example\.com/$EMAIL/g" "home/profiles/$USERNAME/default.nix"
  fi
  
  echo "Đã tạo profile cho $USERNAME."
fi

# ============================================================================
# BOOTSTRAP + REBUILD (theo OS)
# ============================================================================

case $OS in
  darwin)
    echo ""
    echo "═══════════════════════════════════════"
    echo "  BOOTSTRAP macOS"
    echo "═══════════════════════════════════════"
    
    # --- Bootstrap: Nix ---
    if ! command -v nix &> /dev/null; then
      echo "Cài đặt Nix..."
      sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    
    # --- Bootstrap: Homebrew ---
    if ! command -v brew &> /dev/null; then
      echo "Cài đặt Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      
      if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi
    
    # --- Bootstrap: nix-darwin ---
    if ! command -v darwin-rebuild &> /dev/null; then
      echo "Setup Xcode license accept"
      sudo xcodebuild -license accept

      echo "Backing up existing /etc files..."
      [[ -f /etc/zshrc ]] && sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
      [[ -f /etc/zprofile ]] && sudo mv /etc/zprofile /etc/zprofile.before-nix-darwin
      [[ -f /etc/bashrc ]] && sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin

      echo "Cài đặt nix-darwin..."
      sudo nix run nix-darwin -- switch --flake .#$HOSTNAME

      [[ -f /etc/static/bashrc ]] && source /etc/static/bashrc
    fi
    
    # --- Tạo machine config nếu chưa có ---
    if [[ ! -d "hosts/darwin/machines/$HOSTNAME" ]]; then
      echo "Tạo cấu hình cho máy $HOSTNAME từ template..."
      mkdir -p "hosts/darwin/machines/$HOSTNAME"
      cp "hosts/darwin/machines/template/default.nix" "hosts/darwin/machines/$HOSTNAME/default.nix"
    fi

    # --- Rebuild ---
    echo ""
    echo "Xây dựng cấu hình Darwin..."
    if sudo darwin-rebuild switch --flake .#$HOSTNAME; then
      echo "✓ Xây dựng cấu hình Darwin thành công"
    else
      echo "Lỗi: Không thể xây dựng cấu hình Darwin."
      exit 1
    fi
    ;;
    
  nixos)
    echo ""
    echo "═══════════════════════════════════════"
    echo "  BOOTSTRAP NixOS"
    echo "═══════════════════════════════════════"
    
    # --- Bootstrap: Nix (thường đã có sẵn trên NixOS) ---
    if ! command -v nix &> /dev/null; then
      echo "Cài đặt Nix..."
      sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    
    # --- Tạo machine config nếu chưa có ---
    if [[ ! -d "hosts/nixos/machines/$HOSTNAME" ]]; then
      echo "Tạo cấu hình cho $HOSTNAME..."
      mkdir -p "hosts/nixos/machines/$HOSTNAME"
      echo "Tạo cấu hình phần cứng..."
      sudo nixos-generate-config --dir "hosts/nixos/machines/$HOSTNAME"
      echo "Đã tạo cấu hình cho $HOSTNAME."
    fi
    
    # --- Rebuild ---
    echo ""
    echo "Xây dựng cấu hình NixOS..."
    sudo nixos-rebuild switch --flake .#$HOSTNAME
    echo "✓ Xây dựng cấu hình NixOS thành công"
    ;;
    
  nixos-wsl)
    echo ""
    echo "═══════════════════════════════════════"
    echo "  BOOTSTRAP NixOS on WSL"
    echo "═══════════════════════════════════════"
    
    # --- Bật flakes ---
    if ! grep -q "experimental-features" /etc/nix/nix.conf 2>/dev/null; then
      echo "Bật Nix flakes..."
      sudo mkdir -p /etc/nix
      echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
    fi
    
    # --- Rebuild ---
    echo ""
    echo "Xây dựng cấu hình NixOS WSL..."
    sudo nixos-rebuild switch --flake .#wsl
    echo "✓ Xây dựng cấu hình NixOS WSL thành công"
    ;;
    
  ubuntu)
    echo ""
    echo "═══════════════════════════════════════"
    echo "  BOOTSTRAP Ubuntu"
    echo "═══════════════════════════════════════"
    
    # --- APT dependencies (Nix không quản lý APT) ---
    echo "Cài đặt build dependencies..."
    sudo apt update
    sudo apt install -y build-essential curl git zsh flatpak gnome-software-plugin-flatpak gnupg2 \
      autoconf libssl-dev libncurses-dev libreadline-dev zlib1g-dev \
      libbz2-dev libsqlite3-dev libffi-dev liblzma-dev tk-dev \
      zfsutils-linux
    
    # --- Flatpak ---
    echo "Thiết lập Flatpak..."
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    
    # --- Bootstrap: Nix ---
    if [[ -d "/nix" && -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
      echo "Nix đã được cài đặt, bỏ qua"
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    else
      echo "Cài đặt Nix..."
      sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    
    # --- Bật flakes ---
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
    
    # --- Rebuild: Home Manager ---
    echo ""
    echo "Cài đặt home-manager..."
    if nix run github:nix-community/home-manager/release-25.05 -- switch --flake .#$USERNAME@$HOSTNAME; then
      echo "✓ Home Manager switch thành công"
    else
      echo "Thử lại với nix-shell..."
      nix-shell -p nixVersions.stable --run "nix run github:nix-community/home-manager/release-25.05 -- switch --flake .#$USERNAME@$HOSTNAME"
    fi
    
    # --- Platform-specific extras (Nix không quản lý được) ---
    
    # Docker Engine (APT)
    echo ""
    echo "Cài đặt Docker..."
    if ! command -v docker &>/dev/null; then
      echo "Thiết lập Docker repository..."
      sudo install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      sudo chmod a+r /etc/apt/keyrings/docker.gpg
      
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      
      sudo apt update
      sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      
      sudo usermod -aG docker $USER
      echo "✓ Đã cài đặt Docker"
      echo "⚠️  Vui lòng logout và login lại để áp dụng docker group"
    else
      echo "✓ Docker đã được cài đặt"
    fi
    
    # Ghostty (.deb — chưa có trong nixpkgs cho Ubuntu non-NixOS)
    echo ""
    echo "Cài đặt Ghostty..."
    if ! command -v ghostty &>/dev/null; then
      sudo dpkg --remove --force-remove-reinstreq ghostty 2>/dev/null || true
      sudo apt --fix-broken install -y
      sudo apt update
      sudo apt install -y libgtk4-layer-shell0
      
      VERSIONS_FILE="./versions.json"
      if [[ -f "$VERSIONS_FILE" ]] && command -v jq &>/dev/null; then
        GHOSTTY_URL=$(jq -r '.tools.ghostty["ubuntu-deb"]' "$VERSIONS_FILE")
      else
        GHOSTTY_URL="https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.2.2-0-ppa1/ghostty_1.2.2-0.ppa1_amd64_25.10.deb"
      fi
      
      wget -O /tmp/ghostty.deb "$GHOSTTY_URL" || curl -L -o /tmp/ghostty.deb "$GHOSTTY_URL"
      sudo dpkg -i /tmp/ghostty.deb
      sudo apt-get install -f -y
      rm /tmp/ghostty.deb
      echo "✓ Đã cài đặt Ghostty"
    else
      echo "✓ Ghostty đã được cài đặt"
    fi
    
    # Snap packages (Nix không quản lý Snap)
    echo ""
    echo "Cài đặt Snap packages..."
    for pkg in spotify; do
      if ! snap list | grep -q "^$pkg "; then
        echo "Đang cài đặt $pkg..."
        sudo snap install $pkg
        echo "✓ Đã cài đặt $pkg"
      else
        echo "✓ $pkg đã được cài đặt"
      fi
    done
    
    # Podman Desktop (Flatpak — Nix không quản lý Flatpak)
    echo ""
    echo "Cài đặt Podman Desktop..."
    if flatpak list | grep -q "io.podman_desktop.PodmanDesktop" 2>/dev/null; then
      echo "✓ Podman Desktop đã được cài đặt"
    else
      if flatpak install -y flathub io.podman_desktop.PodmanDesktop 2>&1; then
        echo "✓ Đã cài đặt Podman Desktop"
      else
        echo "⚠️  Không thể cài đặt Podman Desktop qua Flatpak"
        echo "Bạn có thể cài thủ công sau: flatpak install flathub io.podman_desktop.PodmanDesktop"
      fi
    fi
    
    # Antigravity trên Ubuntu → quản lý qua Nix module
    echo ""
    echo "Antigravity sẽ được cài đặt và quản lý thông qua Home Manager (module editors.antigravity)."
    echo "Vui lòng chạy 'home-manager switch' nếu chưa thấy editor."
    ;;
    
  *)
    echo "Hệ điều hành không được hỗ trợ: $OS"
    exit 1
    ;;
esac

# ============================================================================
# ASDF LANGUAGES (chung cho tất cả OS)
# ============================================================================

echo ""
echo "═══════════════════════════════════════"
echo "  CÀI ĐẶT NGÔN NGỮ LẬP TRÌNH (asdf)"
echo "═══════════════════════════════════════"

if [[ -f "./asdf-vm/planguage.sh" ]]; then
  chmod +x ./asdf-vm/planguage.sh
  PLANG_ARGS=""
  [[ -n "$LANG_PRESET" ]] && PLANG_ARGS="$PLANG_ARGS --preset $LANG_PRESET"
  [[ -n "$EXTRA_LANGS" ]] && PLANG_ARGS="$PLANG_ARGS --add $EXTRA_LANGS"
  bash ./asdf-vm/planguage.sh $PLANG_ARGS
else
  echo "Cảnh báo: Không tìm thấy file asdf-vm/planguage.sh"
fi


# ============================================================================
# HOÀN TẤT
# ============================================================================

echo ""
echo "═══════════════════════════════════════"
echo "  ✓ THIẾT LẬP HOÀN TẤT!"
echo "═══════════════════════════════════════"
echo ""
echo "Vui lòng khởi động lại terminal hoặc đăng xuất và đăng nhập lại."
echo ""
echo "Các lệnh hữu ích:"
echo "  ./scripts/verify.sh       — Kiểm tra sức khỏe hệ thống"
echo "  ./scripts/update.sh       — Cập nhật dotfiles"
echo "  ./scripts/rollback.sh     — Khôi phục phiên bản trước"
