#!/bin/bash

# ASDF Auto Install Script with Preset Support
# Tự động cài đặt các plugin và phiên bản từ plugins.json theo preset

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_FILE="$SCRIPT_DIR/plugins.json"

# Default preset
PRESET=""
EXTRA_LANGS=""

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

print_header() {
    echo -e "${CYAN}$1${NC}"
}

# Hiển thị help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --preset PRESET    Chọn preset ngôn ngữ (minimal, web-developer, data-scientist,"
    echo "                     devops-engineer, mobile-developer, systems-developer,"
    echo "                     functional-developer, all)"
    echo "  --add LANGS        Thêm ngôn ngữ ngoài preset (cách nhau bởi dấu phẩy)"
    echo "  --list-presets     Hiển thị danh sách presets"
    echo "  --help             Hiển thị hướng dẫn này"
    echo ""
    echo "Ví dụ:"
    echo "  $0 --preset web-developer"
    echo "  $0 --preset minimal --add rust,go"
    echo "  $0 --preset all"
}

# Hiển thị danh sách presets
list_presets() {
    check_plugins_file
    
    print_header "=== DANH SÁCH PRESETS ==="
    echo ""
    
    while IFS='|' read -r name desc; do
        echo -e "${GREEN}$name${NC}: $desc"
        
        # Hiển thị ngôn ngữ asdf
        local asdf_langs=$(jq -r ".presets.\"$name\".asdf | if . == [\"*\"] then \"(tất cả)\" else . | join(\", \") end" "$PLUGINS_FILE")
        echo "  asdf: $asdf_langs"
        
        # Hiển thị rustup
        local rustup=$(jq -r ".presets.\"$name\".rustup" "$PLUGINS_FILE")
        if [ "$rustup" = "true" ]; then
            echo "  rustup: có"
        else
            echo "  rustup: không"
        fi
        echo ""
    done < <(jq -r '.presets | to_entries[] | "\(.key)|\(.value.description)"' "$PLUGINS_FILE")
}

# Kiểm tra file plugins.json
check_plugins_file() {
    if [ ! -f "$PLUGINS_FILE" ]; then
        print_error "Không tìm thấy file plugins.json tại $PLUGINS_FILE"
        exit 1
    fi
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --preset)
                PRESET="$2"
                shift 2
                ;;
            --add)
                EXTRA_LANGS="$2"
                shift 2
                ;;
            --list-presets)
                list_presets
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "Tham số không hợp lệ: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Lấy danh sách ngôn ngữ từ preset
get_preset_languages() {
    local preset=$1
    
    if [ -z "$preset" ]; then
        # Không có preset, trả về tất cả
        jq -r '.asdf | keys[]' "$PLUGINS_FILE"
        return
    fi
    
    # Kiểm tra preset tồn tại
    local preset_exists=$(jq -r ".presets.\"$preset\" // empty" "$PLUGINS_FILE")
    if [ -z "$preset_exists" ]; then
        print_error "Preset '$preset' không tồn tại"
        echo "Sử dụng --list-presets để xem danh sách"
        exit 1
    fi
    
    # Lấy danh sách ngôn ngữ asdf từ preset
    local asdf_langs=$(jq -r ".presets.\"$preset\".asdf[]" "$PLUGINS_FILE")
    
    if echo "$asdf_langs" | grep -q "^\*$"; then
        # Preset "all" - trả về tất cả ngôn ngữ
        jq -r '.asdf | keys[]' "$PLUGINS_FILE"
    else
        echo "$asdf_langs"
    fi
}

# Kiểm tra preset có cần rustup không
preset_needs_rustup() {
    local preset=$1
    
    if [ -z "$preset" ]; then
        # Không có preset, check rustup.enabled
        jq -r '.rustup.enabled // false' "$PLUGINS_FILE"
        return
    fi
    
    jq -r ".presets.\"$preset\".rustup // false" "$PLUGINS_FILE"
}

# Kiểm tra shell và cấu hình source cho rustup
setup_rustup_shell() {
    print_info "Đang kiểm tra shell mặc định của user..."
    
    local user_shell=$(basename "$SHELL")
    local config_file=""
    local source_line='source "$HOME/.cargo/env"'
    
    case "$user_shell" in
        "bash") config_file="$HOME/.bashrc" ;;
        "zsh") config_file="$HOME/.zshrc" ;;
        *)
            if [ -f "$HOME/.zshrc" ]; then
                config_file="$HOME/.zshrc"
            else
                config_file="$HOME/.bashrc"
            fi
            ;;
    esac
    
    if [ -L "$config_file" ]; then
        print_warning "$config_file là symlink do Nix quản lý, bỏ qua cấu hình tự động"
        return 0
    fi
    
    if [ -f "$config_file" ] && grep -q "cargo/env" "$config_file"; then
        print_warning "Cấu hình rustup đã tồn tại trong $config_file"
        return 0
    fi
    
    print_info "Đang thêm cấu hình rustup vào $config_file..."
    echo "" >> "$config_file"
    echo "# Rustup configuration" >> "$config_file"
    echo "$source_line" >> "$config_file"
    
    print_success "Đã thêm cấu hình rustup vào $config_file"
}

# Cài đặt Rustup từ config trong plugins.json
install_rustup() {
    local needs_rustup=$(preset_needs_rustup "$PRESET")
    
    if [ "$needs_rustup" != "true" ]; then
        print_info "Preset không yêu cầu Rustup, bỏ qua..."
        return 0
    fi
    
    print_info "Đang kiểm tra Rustup..."
    
    if command -v rustup &> /dev/null; then
        print_warning "Rustup đã được cài đặt"
        install_rustup_components
        return 0
    fi
    
    local install_url=$(jq -r '.rustup.install_url // "https://sh.rustup.rs"' "$PLUGINS_FILE")
    local default_toolchain=$(jq -r '.rustup.default_toolchain // "stable"' "$PLUGINS_FILE")
    
    print_info "Đang cài đặt Rustup từ $install_url..."
    if curl --proto '=https' --tlsv1.2 -sSf "$install_url" | sh -s -- --no-modify-path -y --default-toolchain "$default_toolchain"; then
        print_success "Đã cài đặt Rustup thành công"
        source "$HOME/.cargo/env"
        setup_rustup_shell
        install_rustup_components
    else
        print_error "Không thể cài đặt Rustup"
        return 1
    fi
}

# Cài đặt rustup components từ config
install_rustup_components() {
    local components=$(jq -r '.rustup.components // [] | .[]' "$PLUGINS_FILE")
    
    if [ -z "$components" ]; then
        return 0
    fi
    
    print_info "Đang cài đặt rustup components..."
    
    for component in $components; do
        if rustup component add "$component" 2>/dev/null; then
            print_success "Đã cài đặt component: $component"
        else
            print_warning "Không thể cài đặt component: $component"
        fi
    done
}

# Kiểm tra asdf
check_asdf() {
    if command -v asdf &> /dev/null; then
        print_success "asdf đã được cài đặt"
        return 0
    fi
    
    print_warning "asdf chưa được cài đặt."
    echo
    read -p "Nhập link tải asdf: " asdf_url
    
    if [ -z "$asdf_url" ]; then
        print_error "Link không được để trống"
        exit 1
    fi
    
    print_info "Đang tải và cài đặt asdf..."
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    curl -fsSL "$asdf_url" -o asdf.tar.gz && tar -xzf asdf.tar.gz
    
    local asdf_bin=$(find . -name "asdf" -type f -executable | head -1)
    if [ -n "$asdf_bin" ]; then
        sudo cp "$asdf_bin" /usr/local/bin/asdf && sudo chmod +x /usr/local/bin/asdf
        print_success "Đã cài đặt asdf"
    else
        print_error "Không tìm thấy file asdf"
        exit 1
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
}

# Hàm thêm plugin
add_plugin() {
    local plugin_name=$1
    local plugin_url=$2
    
    print_info "Đang thêm plugin: $plugin_name"
    
    if asdf plugin list 2>/dev/null | grep -q "^$plugin_name$"; then
        print_warning "Plugin $plugin_name đã tồn tại"
        return 0
    fi
    
    if [ -n "$plugin_url" ]; then
        asdf plugin add "$plugin_name" "$plugin_url" && print_success "Đã thêm plugin $plugin_name"
    else
        asdf plugin add "$plugin_name" && print_success "Đã thêm plugin $plugin_name"
    fi
}

# Hàm cài đặt phiên bản
install_version() {
    local plugin_name=$1
    local version=$2
    
    print_info "Đang cài đặt $plugin_name phiên bản $version..."
    
    if asdf install "$plugin_name" "$version"; then
        print_success "Đã cài đặt $plugin_name phiên bản $version"
        asdf set "$plugin_name" "$version" --home 2>/dev/null || asdf global "$plugin_name" "$version" 2>/dev/null
    else
        print_error "Không thể cài đặt $plugin_name"
        return 1
    fi
}

# Xử lý plugins theo preset
process_plugins_with_preset() {
    local failed_plugins=()
    local failed_installs=()
    
    # Lấy danh sách ngôn ngữ từ preset
    local languages=$(get_preset_languages "$PRESET")
    
    # Thêm extra languages nếu có
    if [ -n "$EXTRA_LANGS" ]; then
        IFS=',' read -ra EXTRA_ARRAY <<< "$EXTRA_LANGS"
        for lang in "${EXTRA_ARRAY[@]}"; do
            languages=$(echo -e "$languages\n$lang")
        done
    fi
    
    # Loại bỏ duplicate
    languages=$(echo "$languages" | sort -u)
    
    print_header "=== CÀI ĐẶT NGÔN NGỮ ==="
    if [ -n "$PRESET" ]; then
        print_info "Preset: $PRESET"
    fi
    if [ -n "$EXTRA_LANGS" ]; then
        print_info "Extra: $EXTRA_LANGS"
    fi
    echo
    
    # Bước 1: Thêm các plugin
    print_info "Bước 1: Thêm các plugin..."
    echo
    
    for plugin_name in $languages; do
        local plugin_repo=$(jq -r ".asdf.\"$plugin_name\".repo // empty" "$PLUGINS_FILE")
        if [ -n "$plugin_repo" ]; then
            if ! add_plugin "$plugin_name" "$plugin_repo"; then
                failed_plugins+=("$plugin_name")
            fi
        else
            print_warning "Không tìm thấy plugin $plugin_name trong config"
        fi
    done
    
    echo
    print_info "Bước 2: Cài đặt phiên bản..."
    echo
    
    # Bước 2: Cài đặt phiên bản
    for plugin_name in $languages; do
        if [[ " ${failed_plugins[*]} " =~ " $plugin_name " ]]; then
            continue
        fi
        
        local version=$(jq -r ".asdf.\"$plugin_name\".version // \"latest\"" "$PLUGINS_FILE")
        
        if [ "$version" = "latest" ] || [ -z "$version" ] || [ "$version" = "null" ]; then
            version=$(asdf latest "$plugin_name" 2>&1)
            if [[ "$version" == *"error"* ]] || [[ "$version" == *"unable"* ]]; then
                print_error "Không thể lấy version mới nhất của $plugin_name"
                failed_installs+=("$plugin_name")
                continue
            fi
        fi
        
        if ! install_version "$plugin_name" "$version"; then
            failed_installs+=("$plugin_name")
        fi
        echo
    done
    
    # Tóm tắt
    echo
    print_header "=== TÓM TẮT KẾT QUẢ ==="
    
    if [ ${#failed_plugins[@]} -eq 0 ] && [ ${#failed_installs[@]} -eq 0 ]; then
        print_success "Tất cả ngôn ngữ đã được cài đặt thành công!"
    else
        [ ${#failed_plugins[@]} -gt 0 ] && print_error "Plugins thất bại: ${failed_plugins[*]}"
        [ ${#failed_installs[@]} -gt 0 ] && print_error "Cài đặt thất bại: ${failed_installs[*]}"
    fi
}

# Main script
main() {
    parse_args "$@"
    
    print_header "╔══════════════════════════════════════╗"
    print_header "║   ASDF & Rustup Installer            ║"
    print_header "╚══════════════════════════════════════╝"
    echo
    
    check_plugins_file
    
    # Cài đặt Rustup nếu cần
    install_rustup
    echo
    
    # Kiểm tra asdf
    check_asdf
    echo
    
    # Xử lý plugins theo preset
    process_plugins_with_preset
    
    echo
    print_info "Chạy 'asdf list' để xem các phiên bản đã cài đặt"
}

main "$@"