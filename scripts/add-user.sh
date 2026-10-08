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

# Cập nhật thông tin (sed qua file tạm — tương thích GNU lẫn BSD/macOS sed)
sed_escape() { printf '%s' "$1" | sed -e 's/[\\|&]/\\&/g'; }
PROFILE_FILE="home/profiles/$USERNAME/default.nix"
sed -e "s|Your Name|$(sed_escape "$FULLNAME")|g" \
    -e "s|your\.email@example\.com|$(sed_escape "$EMAIL")|g" \
    "$PROFILE_FILE" > "$PROFILE_FILE.tmp" && mv "$PROFILE_FILE.tmp" "$PROFILE_FILE"

# Flake chỉ thấy file đã được git track
git add -- "home/profiles/$USERNAME" 2>/dev/null || true

echo "Đã tạo profile cho $USERNAME."
echo "Bạn có thể chỉnh sửa thêm tại: home/profiles/$USERNAME/default.nix"