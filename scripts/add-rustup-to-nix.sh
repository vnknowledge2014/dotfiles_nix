#!/bin/bash

# Script để tự động thêm cấu hình rustup vào Nix home-manager

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Tìm file cấu hình home-manager của user hiện tại
find_home_config() {
    local username=$(whoami)
    local config_file=""
    
    # Tìm trong profile của user
    if [ -f "home/profiles/$username/default.nix" ]; then
        config_file="home/profiles/$username/default.nix"
    elif [ -f "home/profiles/$username.nix" ]; then
        config_file="home/profiles/$username.nix"
    else
        print_error "Không tìm thấy file cấu hình home-manager cho user $username"
        return 1
    fi
    
    echo "$config_file"
}

# Thêm cấu hình rustup vào file Nix
add_rustup_config() {
    local config_file="$1"
    
    # Kiểm tra xem đã có cấu hình rustup chưa
    if grep -q "cargo/env" "$config_file" || grep -q "rustup" "$config_file"; then
        print_warning "Cấu hình rustup đã tồn tại trong $config_file"
        return 0
    fi
    
    print_info "Đang thêm cấu hình rustup vào $config_file..."
    
    # Tạo backup
    cp "$config_file" "$config_file.backup"
    
    # Thêm cấu hình vào cuối file, trước dấu }
    sed -i '' '/^}$/i\
\
  # Rustup configuration\
  programs.zsh.initExtra = lib.mkAfter '\''\
    if [ -f "$HOME/.cargo/env" ]; then\
      source "$HOME/.cargo/env"\
    fi\
  '\'';
' "$config_file"
    
    print_success "Đã thêm cấu hình rustup vào $config_file"
    print_info "File backup được lưu tại $config_file.backup"
}

main() {
    print_info "Đang thêm cấu hình rustup vào Nix home-manager..."
    
    # Tìm file cấu hình
    local config_file
    if ! config_file=$(find_home_config); then
        exit 1
    fi
    
    print_info "Tìm thấy file cấu hình: $config_file"
    
    # Thêm cấu hình
    add_rustup_config "$config_file"
    
    print_success "Hoàn tất! Chạy 'home-manager switch' để áp dụng thay đổi"
}

main "$@"