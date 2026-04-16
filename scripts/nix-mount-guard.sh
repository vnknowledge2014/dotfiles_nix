#!/bin/bash
# ============================================================================
# Nix Mount Guard — Tự động khôi phục /nix mount khi boot
# ============================================================================
# Script này chạy qua LaunchDaemon mỗi lần boot.
# Nếu /nix chưa được mount, nó sẽ tự động sửa.
# ============================================================================

LOG="/var/log/nix-mount-guard.log"
exec >> "$LOG" 2>&1
echo "$(date): nix-mount-guard started"

# Đợi hệ thống khởi động xong
sleep 5

# Kiểm tra /nix đã mount chưa
if mount | grep -q " /nix "; then
  echo "$(date): /nix already mounted. OK."
  exit 0
fi

echo "$(date): /nix NOT mounted. Fixing..."

# Đảm bảo synthetic.conf có entry nix
if ! grep -q '^nix$' /etc/synthetic.conf 2>/dev/null; then
  echo "$(date): Adding 'nix' to /etc/synthetic.conf"
  echo 'nix' >> /etc/synthetic.conf
  /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t
  sleep 2
fi

# Mount Nix Store volume
NIX_DISK=$(diskutil list | grep "Nix Store" | awk '{print $NF}')
if [[ -n "$NIX_DISK" ]]; then
  echo "$(date): Mounting $NIX_DISK at /nix"
  diskutil mount -mountPoint /nix "$NIX_DISK"

  if mount | grep -q " /nix "; then
    echo "$(date): Successfully mounted /nix"
  else
    echo "$(date): FAILED to mount /nix"
    exit 1
  fi
else
  echo "$(date): No 'Nix Store' volume found!"
  exit 1
fi

# Đảm bảo nix-daemon đang chạy
if ! launchctl list | grep -q org.nixos.nix-daemon; then
  echo "$(date): Starting nix-daemon"
  launchctl load -w /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
fi

echo "$(date): nix-mount-guard completed successfully"
