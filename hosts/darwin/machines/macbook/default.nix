{ config, lib, pkgs, ... }:

{
  # Import cấu hình darwin chung
  imports = [];

  # Hostname của máy
  networking.hostName = "macbook";

  # Các cấu hình đặc thù cho máy macbook
  nixpkgs.config = {
    allowUnfree = true;
  };

  # Cài đặt các gói đặc thù cho máy này
  environment.systemPackages = with pkgs; [
    # Thêm các gói riêng cho máy macbook
  ];

  # Cấu hình Homebrew đúng cách - TRỰC TIẾP không dùng extraBrews
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
    
    # Danh sách đầy đủ
    brews = [

    ];
    
    casks = [

    ];
    
    masApps = {
      "Xcode" = 497799835;
    };
  };

  # Cấu hình các dịch vụ đặc thù
  services = {
    # Các dịch vụ đặc thù cho máy macbook
  };

  # Cấu hình macOS đặc thù
  system.defaults = {
    # Cấu hình đặc thù cho macOS trên máy này
  };

  # Các thiết lập khác
  users.users.mike = {
    name = "mike";
    home = "/Users/mike";
  };

  # Phiên bản hệ thống
  system.stateVersion = 4;
}