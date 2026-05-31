{ config, lib, pkgs, hostname, username, ... }:

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
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Fix nixbld group GID
  ids.gids.nixbld = 350;
  
  # Gói macOS cơ bản (gộp từ base.nix)
  environment.systemPackages = with pkgs; [
    m-cli  # Tiện ích CLI cho macOS
    mas    # Mac App Store CLI
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
    # when darwin-rebuild runs brew as root)
    if [[ -d /usr/local ]]; then
      echo "Fixing /usr/local ownership for Homebrew..."
      for dir in /usr/local/Cellar /usr/local/var/homebrew /usr/local/share \
                 /usr/local/lib /usr/local/bin /usr/local/opt /usr/local/Homebrew \
                 /usr/local/Caskroom /usr/local/Frameworks; do
        if [[ -d "$dir" ]]; then
          chown -R ${username}:staff "$dir"
        fi
      done
      # Ensure fish completions dir exists and is writable
      mkdir -p /usr/local/share/fish/vendor_completions.d
      chown -R ${username}:staff /usr/local/share/fish
    fi
  '';
  
  # OpenZFS Tuning — Limit ZFS ARC memory to 16GB (16 * 1024 * 1024 * 1024)
  # Prevents kernel_task / Wired Memory exhaustion under heavy I/O
  environment.etc."zfs/zfs.conf".text = ''
    vfs.zfs.arc.max=17179869184
  '';

  # Phiên bản hệ thống
  system.stateVersion = 4;
}