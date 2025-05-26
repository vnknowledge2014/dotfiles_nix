{ config, lib, pkgs, ... }:

{
  # Cấu hình Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Cài đặt môi trường macOS cơ bản
  environment.systemPackages = with pkgs; [
    coreutils
    gnugrep
    wget
    curl
    git
    m-cli  # Tiện ích CLI cho macOS
    mas    # Mac App Store CLI
    jq
    zsh
    oh-my-zsh
    findutils
    gnused
    gawk
    ripgrep
    fd
  ];
  
  # Thiết lập macOS cơ bản
  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Always";
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };
    
    dock = {
      autohide = true;
      mru-spaces = false;
      show-recents = false;
    };
    
    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      _FXShowPosixPathInTitle = true;
    };
  };
  
  # Các dịch vụ cơ bản
  services.nix-daemon.enable = true;
  
  # Cấu hình shell
  programs.zsh.enable = true;
  
  # Phiên bản hệ thống
  system.stateVersion = 4;
}