{ pkgs, ... }:

# Machine-specific overrides cho máy Ubuntu của rnd
# Tự động import khi hostname trong flake.nix = "ubuntu" (homeConfigurations."rnd@ubuntu")

{
  # Docker: DOCKER_HOST được tự phát hiện trong base/default.nix (kiểm tra socket),
  # không hard-code ở đây.

  # Machine-specific packages
  home.packages = with pkgs; [
    # Thêm packages riêng cho máy này tại đây
  ];
}
