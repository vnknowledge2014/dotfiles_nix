{ config, lib, pkgs, ... }:

{
  # Cấu hình Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Cài đặt môi trường macOS cơ bản
  environment.systemPackages = with pkgs; [
    m-cli  # Tiện ích CLI cho macOS
    mas    # Mac App Store CLI
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
  
  # Cấu hình shell
  programs.zsh.enable = true;
  
  # Phiên bản hệ thống
  system.stateVersion = 4;
}