#!/bin/bash

# Dotfiles Update Script
# Cập nhật dotfiles từ remote repository

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
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Header
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              DOTFILES UPDATE                              ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

cd "$DOTFILES_DIR"

# Kiểm tra có thay đổi local không
print_info "Kiểm tra thay đổi local..."
if [[ -n $(git status --porcelain) ]]; then
    print_warning "Có thay đổi local chưa commit"
    echo ""
    git status --short
    echo ""
    
    read -p "Bạn muốn: (s)tash changes / (c)ommit / (a)bort? " choice
    case $choice in
        s|S)
            print_info "Stashing local changes..."
            git stash push -m "Auto-stash before update $(date +%Y%m%d_%H%M%S)"
            print_success "Đã stash changes"
            ;;
        c|C)
            read -p "Nhập commit message: " commit_msg
            git add -A
            git commit -m "${commit_msg:-Auto-commit before update}"
            print_success "Đã commit changes"
            ;;
        a|A)
            print_info "Hủy update"
            exit 0
            ;;
        *)
            print_error "Lựa chọn không hợp lệ"
            exit 1
            ;;
    esac
fi

# Fetch từ remote
print_info "Fetching từ remote..."
git fetch origin

# Kiểm tra có update không
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")

if [[ -z "$REMOTE" ]]; then
    print_warning "Không có upstream branch"
    exit 0
fi

if [[ "$LOCAL" == "$REMOTE" ]]; then
    print_success "Dotfiles đã up-to-date!"
    exit 0
fi

# Pull changes
print_info "Pulling updates..."
if git pull --rebase origin main 2>/dev/null || git pull --rebase origin master 2>/dev/null; then
    print_success "Đã pull updates thành công"
else
    print_error "Có conflict khi pull. Vui lòng resolve thủ công."
    exit 1
fi

# Rebuild hệ thống
echo ""
read -p "Rebuild hệ thống ngay? [Y/n] " rebuild
if [[ ! "$rebuild" =~ ^[Nn]$ ]]; then
    print_info "Rebuilding..."
    
    OS=$(uname)
    HOSTNAME=$(hostname -s)
    
    if [[ "$OS" == "Darwin" ]]; then
        if darwin-rebuild switch --flake .#$HOSTNAME; then
            print_success "Đã rebuild Darwin thành công"
        else
            print_error "Rebuild thất bại"
            exit 1
        fi
    elif [[ -f /etc/NIXOS ]]; then
        if sudo nixos-rebuild switch --flake .#$HOSTNAME; then
            print_success "Đã rebuild NixOS thành công"
        else
            print_error "Rebuild thất bại"
            exit 1
        fi
    else
        print_info "Ubuntu: Chạy home-manager switch..."
        if nix run home-manager -- switch --flake .#$(whoami)@$HOSTNAME; then
            print_success "Đã apply home-manager thành công"
        else
            print_error "Home-manager switch thất bại"
            exit 1
        fi
    fi
fi

# Chạy health check
echo ""
print_info "Chạy health check..."
if [[ -f "$SCRIPT_DIR/verify.sh" ]]; then
    bash "$SCRIPT_DIR/verify.sh"
fi

echo ""
print_success "Update hoàn tất!"
