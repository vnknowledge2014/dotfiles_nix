{ config, lib, pkgs, ... }:

{
  # Import cấu hình darwin chung
  imports = [];

  # Hostname của máy
  networking.hostName = "your-hostname";

  # Các cấu hình đặc thù cho máy này
  nixpkgs.config = {
    allowUnfree = true;
  };

  # Cài đặt các gói đặc thù cho máy này
  environment.systemPackages = with pkgs; [
    # Thêm các gói riêng cho máy này
  ];

  # Cấu hình Homebrew trực tiếp (không dùng biến extra)
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    
    # Quản lý Brewfile
    global = {
      brewfile = true;
    };
    
    # Danh sách đầy đủ các gói
    brews = [
      "mas"      # Mac App Store CLI
      "python"
      "go"
      "gh"       # GitHub CLI
      # Thêm các brew formulae khác
    ];
    
    casks = [
      "google-chrome"
      "iterm2"
      "rectangle"  # Quản lý cửa sổ
      # Thêm các cask applications khác
    ];
    
    masApps = {
      # Các ứng dụng Mac App Store
      "Xcode" = 497799835;
    };
  };

  # Cấu hình các dịch vụ đặc thù
  services = {
    # Các dịch vụ đặc thù cho máy này
  };

  # Cấu hình macOS đặc thù
  system.defaults = {
    # Cấu hình đặc thù cho macOS trên máy này
  };

  # Các thiết lập khác
  users.users.username = {
    name = "username";
    home = "/Users/username";
  };

  # Phiên bản hệ thống
  system.stateVersion = 4;
}