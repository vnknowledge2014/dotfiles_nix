#!/usr/bin/env bash

set -e

echo "Thêm Máy Mới"
echo "==========="
echo ""

# Kiểm tra tham số
if [[ $# -lt 2 ]]; then
  echo "Cách sử dụng: $0 <hostname> <os-type>"
  echo "os-type: nixos, darwin"
  exit 1
fi

HOSTNAME=$1
OS_TYPE=$2

# Kiểm tra OS type
if [[ "$OS_TYPE" != "nixos" && "$OS_TYPE" != "darwin" ]]; then
  echo "OS type không hợp lệ. Chỉ hỗ trợ: nixos, darwin"
  exit 1
fi

# Xử lý theo OS type
case $OS_TYPE in
  nixos)
    # Kiểm tra cấu hình đã tồn tại
    if [[ -d "hosts/nixos/machines/$HOSTNAME" ]]; then
      echo "Cấu hình cho $HOSTNAME đã tồn tại."
      exit 1
    fi
    
    # Tạo thư mục cấu hình
    echo "Tạo cấu hình cho $HOSTNAME..."
    mkdir -p "hosts/nixos/machines/$HOSTNAME"
    
    MACHINE_DIR="hosts/nixos/machines/$HOSTNAME"

    # Cấu hình phần cứng (chỉ sinh được khi đang chạy trên chính máy NixOS đó)
    if [[ -f "/etc/NIXOS" ]]; then
      echo "Tạo cấu hình phần cứng..."
      nixos-generate-config --show-hardware-config > "$MACHINE_DIR/hardware-configuration.nix"
    else
      echo "Không ở trên NixOS — hãy chạy 'nixos-generate-config --show-hardware-config'"
      echo "trên máy đích và lưu vào $MACHINE_DIR/hardware-configuration.nix."
      echo "{ ... }: { }" > "$MACHINE_DIR/hardware-configuration.nix"
    fi

    # flake.nix import thư mục này → cần default.nix
    cat > "$MACHINE_DIR/default.nix" <<EOF
{ pkgs, username, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader — chỉnh theo máy (systemd-boot cho UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Bắt buộc khi bật ZFS (hosts/nixos/common.nix)
  networking.hostId = "$(head -c 4 /dev/urandom | od -A n -t x4 | tr -d ' \n')";
  boot.zfs.forceImportRoot = false;

  time.timeZone = "Asia/Ho_Chi_Minh";

  users.users.\${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  networking.networkmanager.enable = true;

  # Phiên bản NixOS lúc cài lần đầu — KHÔNG đổi khi nâng cấp
  system.stateVersion = "26.05";
}
EOF
    
    echo "Đã tạo cấu hình cho $HOSTNAME."
    echo "Bạn có thể chỉnh sửa tại: hosts/nixos/machines/$HOSTNAME/"
    ;;
    
  darwin)
    # Kiểm tra cấu hình đã tồn tại
    if [[ -d "hosts/darwin/machines/$HOSTNAME" ]]; then
      echo "Cấu hình cho $HOSTNAME đã tồn tại."
      exit 1
    fi
    
    # Tạo thư mục cấu hình
    echo "Tạo cấu hình cho $HOSTNAME..."
    mkdir -p "hosts/darwin/machines/$HOSTNAME"
    
    # Sao chép từ template
    cp -r hosts/darwin/machines/template/* "hosts/darwin/machines/$HOSTNAME/"
    
    echo "Đã tạo cấu hình cho $HOSTNAME."
    echo "Bạn có thể chỉnh sửa tại: hosts/darwin/machines/$HOSTNAME/"
    ;;
esac

# Flake chỉ thấy file đã được git track
git add -- "hosts/$OS_TYPE/machines/$HOSTNAME" 2>/dev/null || true

echo ""
echo "Bước tiếp theo: thêm entry vào flake.nix, ví dụ:"
if [[ "$OS_TYPE" == "nixos" ]]; then
  echo "  nixosConfigurations.$HOSTNAME = mkNixOS { hostname = \"$HOSTNAME\"; username = \"<user>\"; };"
else
  echo "  darwinConfigurations.$HOSTNAME = mkDarwin { hostname = \"$HOSTNAME\"; username = \"<user>\"; system = \"aarch64-darwin\"; };"
fi