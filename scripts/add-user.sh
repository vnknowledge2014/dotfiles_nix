#!/usr/bin/env bash

set -e

echo "Thêm Người Dùng Mới"
echo "=================="
echo ""

# Kiểm tra tham số
if [[ $# -lt 1 ]]; then
  echo "Cách sử dụng: $0 <username> [fullname] [email]"
  exit 1
fi

USERNAME=$1
FULLNAME=${2:-"Your Name"}
EMAIL=${3:-"your.email@example.com"}

# Kiểm tra profile đã tồn tại
if [[ -d "home/profiles/$USERNAME" ]]; then
  echo "Profile cho $USERNAME đã tồn tại."
  exit 1
fi

# Tạo thư mục profile
echo "Tạo profile cho $USERNAME..."
mkdir -p "home/profiles/$USERNAME"
cp -r home/profiles/template/* "home/profiles/$USERNAME/"

# Cập nhật thông tin
sed -i "s/Your Name/$FULLNAME/g" "home/profiles/$USERNAME/default.nix"
sed -i "s/your\.email@example\.com/$EMAIL/g" "home/profiles/$USERNAME/default.nix"

echo "Đã tạo profile cho $USERNAME."
echo "Bạn có thể chỉnh sửa thêm tại: home/profiles/$USERNAME/default.nix"