{ pkgs, username, ... }:

{
  wsl = {
    enable = true;
    defaultUser = username;
    startMenuLaunchers = true;

    # Tự động mount các đĩa Windows
    wslConf.automount.options = "metadata,umask=22,fmask=11";
    # resolv.conf do WSL tự sinh (theo DNS của Windows/VPN) — không đặt networking.nameservers
  };

  # NixOS-WSL không import hosts/nixos/common.nix (bootloader/ZFS không áp dụng
  # cho kernel của Microsoft) nên khai báo lại phần chung cần thiết ở đây.
  nix = {
    package = pkgs.lix;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Asia/Ho_Chi_Minh";

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Cho phép chạy binary dựng sẵn (dynamic-linked) — asdf tải prebuilt cho
  # nodejs, bun, deno, zig, flutter, java... và VS Code Remote server cũng cần.
  programs.nix-ld.enable = true;

  networking.firewall.enable = false;

  # Vô hiệu hóa các dịch vụ không cần thiết trong WSL
  services = {
    xserver.enable = false;
    pipewire.enable = false;
    printing.enable = false;
  };

  # Phiên bản NixOS lúc cài lần đầu — KHÔNG đổi khi nâng cấp nixpkgs
  system.stateVersion = "26.05";
}
