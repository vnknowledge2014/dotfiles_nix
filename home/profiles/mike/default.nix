{ lib, pkgs, ... }:

# ═══════════════════════════════════════════════════════════
# PROFILE: mike (macOS)
# ═══════════════════════════════════════════════════════════
# Tạo profile mới cho team member:
#   cp -r home/profiles/mike/ home/profiles/<tên-bạn>/
#   Sửa Git identity + plugins, rồi thêm entry vào flake.nix
# Hoặc chạy: ./scripts/add-user.sh <tên-bạn>
# ═══════════════════════════════════════════════════════════
{
  imports = [
    ../base
  ];

  # oh-my-zsh: base đã có "git" "docker", darwin.nix thêm "macos".
  # Thêm plugin riêng tại đây (danh sách được cộng dồn, không ghi đè):
  # modules.shell.zsh.ohmyzsh.plugins = [ "kubectl" ];

  # Greeting
  modules.shell.zsh.extraConfig = lib.mkAfter ''
    echo "Welcome to your development environment, Mike!"
    echo "Remember to stay hydrated and take breaks while coding!"
  '';

  # Git Identity
  programs.git.settings.user = {
    name = "architectureman";
    email = "vnknowledge2014@gmail.com";
  };

  # macOS-specific packages (thêm ngoài base)
  home.packages = with pkgs; [
    # Thêm packages riêng cho Mike tại đây
  ];
}
