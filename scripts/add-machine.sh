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
    
    # Tạo cấu hình phần cứng
    if [[ -f "/etc/NIXOS" ]]; then
      echo "Tạo cấu hình phần cứng..."
      sudo nixos-generate-config --dir "hosts/nixos/machines/$HOSTNAME"
    else
      echo "Không thể tạo cấu hình phần cứng. Hãy tạo thủ công sau."
      cp -r hosts/nixos/machines/template/* "hosts/nixos/machines/$HOSTNAME/"
    fi
    
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

# Cập nhật flake.nix
echo "Cập nhật flake.nix..."
echo "Hãy thêm cấu hình cho $HOSTNAME vào flake.nix theo hướng dẫn trong README.md"