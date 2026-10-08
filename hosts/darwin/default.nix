{
  pkgs,
  hostname,
  username,
  ...
}:

{
  # Import các thành phần cấu hình theo thứ tự
  imports = [
    # Cấu hình Homebrew
    ./homebrew.nix

    # Cấu hình cho XCode nếu có
    ./xcode.nix
  ];

  # Thiết lập cơ bản
  networking.hostName = hostname;

  # Set primary user for nix-darwin (required for certain options)
  system.primaryUser = username;

  # Cấu hình Nix
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Fix nixbld group GID
  ids.gids.nixbld = 350;

  # Gói macOS cơ bản (gộp từ base.nix)
  environment.systemPackages = with pkgs; [
    m-cli # Tiện ích CLI cho macOS
    mas # Mac App Store CLI
  ];

  # Cấu hình shell
  programs.zsh.enable = true;

  # Fix LaunchAgents permissions and Homebrew directories
  system.activationScripts.preActivation.text = ''
    echo "Fixing LaunchAgents directory permissions..."
    mkdir -p /Users/${username}/Library/LaunchAgents
    chown ${username}:staff /Users/${username}/Library/LaunchAgents
    chmod 755 /Users/${username}/Library/LaunchAgents

    # Ensure synthetic.conf exists for nix-darwin activation
    if [[ ! -f /etc/synthetic.conf ]]; then
      touch /etc/synthetic.conf
    fi

    # Fix /usr/local ownership for Homebrew (prevents permission errors
    # when darwin-rebuild runs brew as root).
    # - Thư mục riêng của Homebrew: chown -R, nhưng chỉ khi owner đã bị lệch
    #   (tránh duyệt lại toàn bộ cây ở mỗi lần rebuild).
    # - bin/lib/share/...: dùng chung với installer khác (OpenZFS, Docker...) —
    #   chỉ sửa owner của chính thư mục để brew tạo được symlink, không đệ quy.
    if [[ -d /usr/local ]]; then
      for dir in /usr/local/Cellar /usr/local/Caskroom /usr/local/Homebrew \
                 /usr/local/var/homebrew /usr/local/opt /usr/local/Frameworks; do
        if [[ -d "$dir" ]] && [[ "$(stat -f %Su "$dir")" != "${username}" || -n "$(find "$dir" -maxdepth 2 ! -user ${username} -print -quit)" ]]; then
          echo "Fixing ownership of $dir for Homebrew..."
          chown -R ${username}:staff "$dir"
        fi
      done
      for dir in /usr/local/bin /usr/local/lib /usr/local/share /usr/local/include /usr/local/etc; do
        if [[ -d "$dir" && "$(stat -f %Su "$dir")" != "${username}" ]]; then
          chown ${username}:staff "$dir"
        fi
      done
      # Ensure fish completions dir exists and is writable
      mkdir -p /usr/local/share/fish/vendor_completions.d
      chown -R ${username}:staff /usr/local/share/fish
    fi
  '';

  # OpenZFS Tuning — Limit ZFS ARC memory to 16GB (16 * 1024 * 1024 * 1024)
  # Prevents kernel_task / Wired Memory exhaustion under heavy I/O
  # OpenZFS on macOS đọc /etc/zfs/zsysctl.conf (zpool-import-all.sh → zsysctl -f)
  # lúc boot; cú pháp vfs.zfs.* trong zfs.conf là của FreeBSD và không có tác dụng.
  # Áp dụng ngay không cần reboot: sudo zsysctl -f /etc/zfs/zsysctl.conf
  environment.etc."zfs/zsysctl.conf".text = ''
    kstat.zfs.darwin.tunable.zfs_arc.max=17179869184
  '';

  # Phiên bản hệ thống
  system.stateVersion = 4;
}
