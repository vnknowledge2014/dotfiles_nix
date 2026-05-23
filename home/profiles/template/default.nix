{ config, lib, pkgs, system, inputs, ... }:

# ═══════════════════════════════════════════════════════════
# TEMPLATE PROFILE — Copy để tạo profile mới cho team member
# ═══════════════════════════════════════════════════════════
# Cách dùng:
#   1. cp -r template/ <tên-bạn>/
#   2. Sửa Git identity (userName, userEmail)
#   3. Override plugins, aliases, packages theo ý thích
#   4. Thêm machine config: cp machines/example.nix machines/<hostname>.nix
#   5. Thêm entry vào flake.nix
#
# Hoặc chạy: ./scripts/add-user.sh <tên-bạn>
# ═══════════════════════════════════════════════════════════

{
  # Kế thừa base profile — tất cả modules đã được import và bật sẵn ở đây
  imports = [
    ../base
  ];

  # Override: oh-my-zsh plugins (base mặc định: ["git" "docker"])
  # Thêm plugin theo OS: "macos", "ubuntu", "wsl"
  modules.shell.zsh.ohmyzsh.plugins = [ "git" "docker" ];

  # Greeting (tùy chỉnh)
  modules.shell.zsh.extraConfig = lib.mkAfter ''
    echo "Welcome to your development environment!"
  '';

  # Git Identity — BẮT BUỘC SỬA cho đúng tên của bạn
  programs.git = {
    userName = "Your Name";
    userEmail = "your.email@example.com";
  };

  # Packages cá nhân (thêm ngoài base)
  home.packages = with pkgs; [
    # Thêm packages riêng của bạn tại đây
  ];

  # Session variables cá nhân
  home.sessionVariables = {
    EDITOR = "nvim";
  };
}