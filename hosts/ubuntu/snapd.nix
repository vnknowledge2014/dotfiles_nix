{ config, lib, ... }:

let
  # Cấu hình Snapd chung
  commonSnaps = [
    "spotify"
  ];

  # Cho phép ghi đè từ cấu hình người dùng
  extraSnaps = config.extraSnaps or [ ];
in
{
  # Tích hợp Snapd
  # Không cài snapd tự động trong activation (cần sudo + systemd); WSL mặc định
  # không có systemd và cũng không cần app GUI → bỏ qua.
  home.activation.snapPackages = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    SNAP=/usr/bin/snap
    if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
      : # WSL — bỏ qua snap
    elif [ ! -x "$SNAP" ] || [ ! -d /run/systemd/system ]; then
      echo "snapd chưa sẵn sàng — bỏ qua snap. Cài bằng: sudo apt install -y snapd"
    else
      PACKAGES=(${lib.concatStringsSep " " (map lib.escapeShellArg (commonSnaps ++ extraSnaps))})
      for pkg in "''${PACKAGES[@]}"; do
        if ! "$SNAP" list "$pkg" >/dev/null 2>&1; then
          echo "Đang cài đặt snap $pkg..."
          $DRY_RUN_CMD /usr/bin/sudo "$SNAP" install "$pkg" || echo "Không cài được snap $pkg"
        fi
      done
    fi
  '';
}
