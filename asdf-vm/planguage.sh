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

# Kiểm tra shell và cấu hình source cho rustup
setup_rustup_shell() {
    print_info "Đang kiểm tra shell mặc định của user..."
    
    local user_shell=$(basename "$SHELL")
    local config_file=""
    local source_line='source "$HOME/.cargo/env"'
    
    # Phát hiện shell mặc định của user, không phải shell đang chạy script
    case "$user_shell" in
        "bash")
            config_file="$HOME/.bashrc"
            print_info "Shell mặc định là bash, sẽ cấu hình trong .bashrc"
            ;;
        "zsh")
            config_file="$HOME/.zshrc"
            print_info "Shell mặc định là zsh, sẽ cấu hình trong .zshrc"
            ;;
        *)
            print_warning "Shell không được hỗ trợ: $user_shell, kiểm tra cả .bashrc và .zshrc"
            # Ưu tiên zsh nếu file .zshrc tồn tại, nếu không thì dùng bash
            if [ -f "$HOME/.zshrc" ]; then
                config_file="$HOME/.zshrc"
                print_info "Tìm thấy .zshrc, sẽ cấu hình trong .zshrc"
            else
                config_file="$HOME/.bashrc"
                print_info "Không tìm thấy .zshrc, sẽ cấu hình trong .bashrc"
            fi
            ;;
    esac
    
    # Kiểm tra xem file có phải là symlink không (do Nix quản lý)
    if [ -L "$config_file" ]; then
        print_warning "$config_file là symlink do Nix quản lý, bỏ qua cấu hình tự động"
        print_info "Vui lòng thêm 'source \"\$HOME/.cargo/env\"' vào cấu hình Nix của bạn"
        return 0
    fi
    
    # Kiểm tra xem đã có cấu hình chưa
    if [ -f "$config_file" ] && grep -q "cargo/env" "$config_file"; then
        print_warning "Cấu hình rustup đã tồn tại trong $config_file"
        return 0
    fi
    
    # Thêm cấu hình vào file shell
    print_info "Đang thêm cấu hình rustup vào $config_file..."
    echo "" >> "$config_file"
    echo "# Rustup configuration" >> "$config_file"
    echo "$source_line" >> "$config_file"
    
    print_success "Đã thêm cấu hình rustup vào $config_file"
}

# Cài đặt Rustup
install_rustup() {
    print_info "Đang kiểm tra Rustup..."
    
    if command -v rustup &> /dev/null; then
        print_warning "Rustup đã được cài đặt, bỏ qua..."
        return 0
    fi
    
    print_info "Đang cài đặt Rustup..."
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path -y; then
        print_success "Đã cài đặt Rustup thành công"
        
        # Source cargo env cho session hiện tại
        source "$HOME/.cargo/env"
        
        # Cấu hình shell cho các session tương lai
        setup_rustup_shell
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

# Hàm cài đặt phiên bản
install_version() {
    local plugin_name=$1
    local version=$2
    
    print_info "Đang cài đặt $plugin_name phiên bản $version..."
    
    if asdf install "$plugin_name" "$version"; then
        print_success "Đã cài đặt $plugin_name phiên bản $version"
        
        # Đặt phiên bản trong home directory
        if asdf set -u "$plugin_name" "$version" --home; then
            print_success "Đã đặt $plugin_name $version làm phiên bản mặc định"
        else
            print_warning "Không thể đặt $plugin_name $version làm phiên bản mặc định"
        fi
    else
        print_error "Không thể cài đặt $plugin_name"
        return 1
    fi
}

# Xử lý plugins từ file JSON
process_plugins() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local plugins_file="$script_dir/plugins.json"
    
    if [ ! -f "$plugins_file" ]; then
        print_error "Không tìm thấy file plugins.json"
        exit 1
    fi
    
    local failed_plugins=()
    local failed_installs=()
    
    # Bước 1: Thêm các plugin
    print_info "Bước 1: Thêm các plugin..."
    echo
    
    while IFS='|' read -r plugin_name plugin_url; do
        if ! add_plugin "$plugin_name" "$plugin_url"; then
            failed_plugins+=("$plugin_name")
        fi
    done < <(jq -r '.plugins | to_entries[] | "\(.key)|\(.value)"' "$plugins_file")
    
    echo
    print_info "Bước 2: Cài đặt phiên bản..."
    echo
    
    # Bước 2: Cài đặt phiên bản
    while IFS='|' read -r plugin_name plugin_url; do
        # Bỏ qua các plugin không thêm được
        if [[ " ${failed_plugins[*]} " =~ " $plugin_name " ]]; then
            print_warning "Bỏ qua cài đặt $plugin_name vì plugin không thể thêm được"
            continue
        fi
        
        # Lấy phiên bản từ config hoặc latest
        local version
        version=$(jq -r ".versions.\"$plugin_name\" // empty" "$plugins_file")
        
        if [ -z "$version" ] || [ "$version" = "null" ]; then
            # Lấy phiên bản mới nhất từ asdf
            version=$(asdf latest "$plugin_name")
            if [ -z "$version" ]; then
                print_error "Không thể lấy được phiên bản mới nhất của $plugin_name"
                failed_installs+=("$plugin_name")
                continue
            fi
        fi
        
        if ! install_version "$plugin_name" "$version"; then
            failed_installs+=("$plugin_name")
        fi
        echo
    done < <(jq -r '.plugins | to_entries[] | "\(.key)|\(.value)"' "$plugins_file")
    
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
    
    # Xử lý plugins từ JSON
    process_plugins
    
    echo
    print_info "Chạy 'asdf list' để xem các phiên bản đã cài đặt"
    print_info "Chạy 'asdf current' để xem các phiên bản hiện tại"
}

# Chạy script
main "$@"