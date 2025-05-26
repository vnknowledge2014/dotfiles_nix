{ config, lib, pkgs, ... }:

let
  # Cấu hình Snapd chung
  commonSnaps = [
    "code" 
    "spotify"
  ];
  
  # Cho phép ghi đè từ cấu hình người dùng
  extraSnaps = config.extraSnaps or [];
in
{
  # Tích hợp Snapd
  home.activation.snapPackages = config.lib.dag.entryAfter ["writeBoundary"] ''
    if command -v snap > /dev/null 2>&1; then
      echo "Cài đặt các gói snap..."
      
      # Kết hợp danh sách
      PACKAGES=(${lib.concatStringsSep " " (map (x: "\"${x}\"") (commonSnaps ++ extraSnaps))})
      
      for pkg in "''${PACKAGES[@]}"; do
        if ! snap list | grep -q "^$pkg"; then
          echo "Đang cài đặt $pkg..."
          sudo snap install $pkg
        fi
      done
    else
      echo "Snapd không được cài đặt. Cài đặt snapd trước..."
      sudo apt update
      sudo apt install -y snapd
    fi
  '';
}