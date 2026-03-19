#!/bin/bash

# Dotfiles Update Script
# Cập nhật tất cả: git, nix flake, rebuild, homebrew, snap, flatpak, asdf

set -e

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERR]${NC} $1"; }
print_section() { echo ""; echo -e "${BLUE}═══ $1 ═══${NC}"; }

# Header
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              DOTFILES UPDATE                              ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

cd "$DOTFILES_DIR"

# Detect OS
detect_os() {
  if [[ "$(uname)" == "Darwin" ]]; then echo "darwin"
  elif [[ -f /etc/NIXOS ]]; then
    grep -q "microsoft" /proc/sys/kernel/osrelease 2>/dev/null && echo "nixos-wsl" || echo "nixos"
  elif grep -q "Ubuntu" /etc/os-release 2>/dev/null; then echo "ubuntu"
  else echo "unknown"; fi
}

OS=$(detect_os)
HOSTNAME=$(hostname -s)
USERNAME=$(whoami)

echo "Hệ thống: $OS | Host: $HOSTNAME | User: $USERNAME"

# ============================================================================
# 1. GIT: Pull dotfiles mới nhất
# ============================================================================
print_section "Git Pull"

if [[ -n $(git status --porcelain) ]]; then
    print_warning "Có thay đổi local chưa commit"
    git status --short
    echo ""
    read -p "Bạn muốn: (s)tash / (c)ommit / (a)bort? " choice
    case $choice in
        s|S) git stash push -m "Auto-stash $(date +%Y%m%d_%H%M%S)"; print_success "Stashed" ;;
        c|C) read -p "Commit message: " msg; git add -A; git commit -m "${msg:-Auto-commit}"; print_success "Committed" ;;
        a|A) print_info "Hủy"; exit 0 ;;
        *) print_error "Lựa chọn không hợp lệ"; exit 1 ;;
    esac
fi

git fetch origin
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")

if [[ -n "$REMOTE" && "$LOCAL" != "$REMOTE" ]]; then
    git pull --rebase origin main 2>/dev/null || git pull --rebase origin master 2>/dev/null
    print_success "Pulled updates"
else
    print_success "Git đã up-to-date"
fi

# ============================================================================
# 2. NIX FLAKE: Cập nhật inputs (nixpkgs, home-manager, etc.)
# ============================================================================
print_section "Nix Flake Update"

if command -v nix &>/dev/null; then
    read -p "Cập nhật Nix flake inputs (nixpkgs, home-manager, ...)? [Y/n] " update_flake
    if [[ ! "$update_flake" =~ ^[Nn]$ ]]; then
        nix flake update
        print_success "Flake inputs đã cập nhật"
    else
        print_info "Bỏ qua flake update"
    fi
else
    print_warning "Nix chưa cài đặt"
fi

# ============================================================================
# 3. NIX REBUILD: Áp dụng config mới
# ============================================================================
if [[ "$OS" == "darwin" ]]; then
    print_section "Colima AI (Apple Silicon)"
    read -p "Bạn có muốn bật Colima AI (hỗ trợ GPU, cần cài thêm Krunkit)? [y/N] " enable_ai
    
    MAC_CONFIG="hosts/darwin/machines/$HOSTNAME/default.nix"
    if [[ -f "$MAC_CONFIG" ]]; then
        if [[ "$enable_ai" =~ ^[Yy]$ ]]; then
            sed -i '' 's/enableColimaAI = false;/enableColimaAI = true;/' "$MAC_CONFIG"
            print_success "Đã BẬT cấu hình Colima AI"
        else
            sed -i '' 's/enableColimaAI = true;/enableColimaAI = false;/' "$MAC_CONFIG"
            print_info "Đã TẮT cấu hình Colima AI"
        fi
    fi
fi

print_section "Nix Rebuild"

case $OS in
    darwin)
        print_info "darwin-rebuild switch..."
        if sudo darwin-rebuild switch --flake .#$HOSTNAME; then
            print_success "Darwin rebuild thành công"
        else
            print_error "Darwin rebuild thất bại"
            exit 1
        fi
        ;;
    nixos|nixos-wsl)
        FLAKE_TARGET=$([[ "$OS" == "nixos-wsl" ]] && echo "wsl" || echo "$HOSTNAME")
        print_info "nixos-rebuild switch --flake .#$FLAKE_TARGET..."
        if sudo nixos-rebuild switch --flake .#$FLAKE_TARGET; then
            print_success "NixOS rebuild thành công"
        else
            print_error "NixOS rebuild thất bại"
            exit 1
        fi
        ;;
    ubuntu)
        print_info "home-manager switch..."
        if nix run github:nix-community/home-manager/release-25.05 -- switch --flake .#$USERNAME@$HOSTNAME; then
            print_success "Home Manager switch thành công"
        else
            print_error "Home Manager switch thất bại"
            exit 1
        fi
        ;;
esac

# ============================================================================
# 4. HOMEBREW (macOS only)
# ============================================================================
if [[ "$OS" == "darwin" ]] && command -v brew &>/dev/null; then
    print_section "Homebrew"
    brew update
    brew upgrade
    brew cleanup
    print_success "Homebrew đã cập nhật"
fi

# ============================================================================
# 5. SNAP (Ubuntu only)
# ============================================================================
if [[ "$OS" == "ubuntu" ]] && command -v snap &>/dev/null; then
    print_section "Snap"
    sudo snap refresh
    print_success "Snap đã cập nhật"
fi

# ============================================================================
# 6. FLATPAK (Ubuntu only)
# ============================================================================
if [[ "$OS" == "ubuntu" ]] && command -v flatpak &>/dev/null; then
    print_section "Flatpak"
    flatpak update -y
    print_success "Flatpak đã cập nhật"
fi

# ============================================================================
# 7. ASDF (tất cả OS)
# ============================================================================
if command -v asdf &>/dev/null; then
    print_section "asdf Plugins"
    asdf plugin update --all 2>/dev/null && print_success "asdf plugins đã cập nhật" || print_warning "Không thể cập nhật asdf plugins"
fi

# ============================================================================
# 8. RUSTUP (tất cả OS)
# ============================================================================
if command -v rustup &>/dev/null; then
    print_section "Rustup"
    rustup update && print_success "Rust toolchain đã cập nhật"
    rustup self update 2>/dev/null && print_success "Rustup đã cập nhật" || true
fi

# ============================================================================
# 9. NIX GC: Dọn rác (tùy chọn)
# ============================================================================
print_section "Nix Garbage Collection"
read -p "Dọn Nix store (xóa generations cũ > 30 ngày)? [y/N] " gc_choice
if [[ "$gc_choice" =~ ^[Yy]$ ]]; then
    nix-collect-garbage --delete-older-than 30d
    print_success "Nix store đã được dọn dẹp"
else
    print_info "Bỏ qua"
fi

# ============================================================================
# 9. HEALTH CHECK
# ============================================================================
print_section "Health Check"
if [[ -f "$SCRIPT_DIR/verify.sh" ]]; then
    bash "$SCRIPT_DIR/verify.sh"
fi

echo ""
print_success "═══ UPDATE HOÀN TẤT! ═══"
echo ""
