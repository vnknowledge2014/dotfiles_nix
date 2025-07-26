#!/bin/bash

# ASDF Auto Install Script
# Tự động cài đặt các plugin và phiên bản mới nhất của các ngôn ngữ lập trình

set -e  # Dừng script nếu có lỗi

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Hàm in thông báo với màu
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

# Cài đặt Rustup
install_rustup() {
    print_info "Đang kiểm tra Rustup..."
    
    if command -v rustup &> /dev/null; then
        print_warning "Rustup đã được cài đặt, bỏ qua..."
        return 0
    fi
    
    print_info "Đang cài đặt Rustup..."
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        print_success "Đã cài đặt Rustup thành công"
        # Source cargo env
        source "$HOME/.cargo/env"
    else
        print_error "Không thể cài đặt Rustup"
        return 1
    fi
}

# Kiểm tra asdf đã được cài đặt chưa
check_asdf() {
    if ! command -v asdf &> /dev/null; then
        print_error "asdf chưa được cài đặt. Vui lòng cài đặt asdf trước khi chạy script này."
        echo "Tham khảo: https://asdf-vm.com/guide/getting-started.html"
        exit 1
    fi
    print_success "asdf đã được cài đặt"
}

# Hàm thêm plugin
add_plugin() {
    local plugin_name=$1
    local plugin_url=$2
    
    print_info "Đang thêm plugin: $plugin_name"
    
    if asdf plugin list | grep -q "^$plugin_name$"; then
        print_warning "Plugin $plugin_name đã tồn tại, bỏ qua..."
        return 0
    fi
    
    if [ -n "$plugin_url" ]; then
        if asdf plugin add "$plugin_name" "$plugin_url"; then
            print_success "Đã thêm plugin $plugin_name"
        else
            print_error "Không thể thêm plugin $plugin_name"
            return 1
        fi
    else
        if asdf plugin add "$plugin_name"; then
            print_success "Đã thêm plugin $plugin_name"
        else
            print_error "Không thể thêm plugin $plugin_name"
            return 1
        fi
    fi
}

# Hàm cài đặt phiên bản mới nhất
install_latest() {
    local plugin_name=$1
    local version=""
    
    # Xử lý đặc biệt cho Java, Haskell và Elixir
    if [[ "$plugin_name" =~ ^(java|haskell|elixir)$ ]]; then
        print_info "Đang lấy danh sách phiên bản cho $plugin_name..."
        if ! asdf list all "$plugin_name"; then
            print_error "Không thể lấy danh sách phiên bản của $plugin_name"
            return 1
        fi
        
        echo
        read -p "Nhập phiên bản $plugin_name bạn muốn cài đặt: " version
        
        if [ -z "$version" ]; then
            print_error "Phiên bản không được để trống"
            return 1
        fi
        
        print_info "Đang cài đặt $plugin_name phiên bản $version..."
    else
        # Lấy phiên bản mới nhất từ asdf
        version=$(asdf latest "$plugin_name")
        if [ -z "$version" ]; then
            print_error "Không thể lấy được phiên bản mới nhất của $plugin_name"
            return 1
        fi
        print_info "Đang cài đặt $plugin_name phiên bản $version..."
    fi
    
    if asdf install "$plugin_name" "$version"; then
        print_success "Đã cài đặt $plugin_name phiên bản $version"
        
        # Đặt phiên bản trong home directory
        if asdf set -u "$plugin_name" "$version" --home; then
            print_success "Đã đặt $plugin_name $version làm phiên bản mặc định trong home directory"
        else
            print_warning "Không thể đặt $plugin_name $version làm phiên bản mặc định"
        fi
    else
        print_error "Không thể cài đặt $plugin_name"
        return 1
    fi
}

# Đọc danh sách plugins từ file JSON
load_plugins() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local plugins_file="$script_dir/plugins.json"
    
    if [ ! -f "$plugins_file" ]; then
        print_error "Không tìm thấy file plugins.json"
        exit 1
    fi
    
    # Đọc JSON và chuyển thành associative array
    while IFS="=" read -r key value; do
        plugins["$key"]="$value"
    done < <(jq -r '.plugins | to_entries[] | "\(.key)=\(.value)"' "$plugins_file")
}

# Main script
main() {
    print_info "Bắt đầu cài đặt Rustup và các plugin asdf..."
    echo
    
    # Cài đặt Rustup
    install_rustup
    echo
    
    # Kiểm tra asdf
    check_asdf
    echo
    
    # Đọc danh sách plugins
    declare -A plugins
    load_plugins
    
    # Thêm tất cả các plugin
    print_info "Bước 1: Thêm các plugin..."
    echo
    failed_plugins=()
    
    for plugin in "${!plugins[@]}"; do
        if ! add_plugin "$plugin" "${plugins[$plugin]}"; then
            failed_plugins+=("$plugin")
        fi
    done
    
    echo
    print_info "Bước 2: Cài đặt phiên bản mới nhất..."
    echo
    
    # Cài đặt phiên bản mới nhất cho các plugin đã thêm thành công
    failed_installs=()
    
    for plugin in "${!plugins[@]}"; do
        # Bỏ qua các plugin không thêm được
        if [[ " ${failed_plugins[*]} " =~ " $plugin " ]]; then
            print_warning "Bỏ qua cài đặt $plugin vì plugin không thể thêm được"
            continue
        fi
        
        if ! install_latest "$plugin"; then
            failed_installs+=("$plugin")
        fi
        echo
    done
    
    # Tóm tắt kết quả
    echo
    print_info "=== TÓM TẮT KẾT QUẢ ==="
    
    if [ ${#failed_plugins[@]} -eq 0 ] && [ ${#failed_installs[@]} -eq 0 ]; then
        print_success "Tất cả plugin và ngôn ngữ đã được cài đặt thành công!"
    else
        if [ ${#failed_plugins[@]} -gt 0 ]; then
            print_error "Các plugin không thể thêm được: ${failed_plugins[*]}"
        fi
        
        if [ ${#failed_installs[@]} -gt 0 ]; then
            print_error "Các ngôn ngữ không thể cài đặt được: ${failed_installs[*]}"
        fi
    fi
    
    echo
    print_info "Chạy 'asdf list' để xem các phiên bản đã cài đặt"
    print_info "Chạy 'asdf current' để xem các phiên bản hiện tại"
}

# Chạy script
main "$@"