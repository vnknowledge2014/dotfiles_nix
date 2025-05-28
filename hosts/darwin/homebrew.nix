{ config, lib, pkgs, ... }:

let
  # Cấu hình Homebrew chung
  commonBrews = [

  ];
  
  commonCasks = [

  ];
  
  commonMasApps = {
    # Các ứng dụng Mac App Store chung
  };
  
  # Cho phép ghi đè từ cấu hình máy
  extraBrews = config.extraBrews or [];
  extraCasks = config.extraCasks or [];
  extraMasApps = config.extraMasApps or {};
in
{
  # Cấu hình Homebrew
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
    
    # Kết hợp các danh sách
    brews = commonBrews ++ extraBrews;
    casks = commonCasks ++ extraCasks;
    masApps = commonMasApps // extraMasApps;
  };

  # Tích hợp Homebrew vào môi trường
  environment.shellInit = ''
    # Tích hợp với Homebrew
    if [ -f /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  '';
}