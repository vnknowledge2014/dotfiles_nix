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

  # Cấu hình Homebrew
  extraBrews = [
    "atuin"
    "yazi"
    "lazygit"
    "lazydocker"
    "kubernetes-cli"
    "k9s"
    "btop"
    "posting"
    "podman-tui"
    "podman"
    "podman-compose"
    "asdf"
    "mpv"
    "pkg-config" 
    "openssl@3" 
    "librdkafka" 
    "zlib"
    "p7zip"
    "pkg-config"
  ];

  extraCasks = [
    "font-fira-code-nerd-font"
    "gotiengviet"
    "ghostty"
    "trae"
    "zed"
    "brave-browser"
    "arc"
    "zen"
    "orbstack"
    "podman-desktop"
    "postman"
    "apidog"
    "gitbutler"
    "cloudflare-warp"
    "mountain-duck"
    "localsend"
    "ollama-app"
    "iina"
    "zalo"
  ];

  extraMasApps = {
    # "Xcode" = 497799835;
    "Telegram" = 747648890;
    "Focus - Pomodoro & Focus Timer" = 1554411065;
    "NCalc Scientific Calculator +" = 1449106995;
    "OneDrive" = 823766827;
    "TeraBox: 1TB Cloud & AI Space" = 1509453185;
    # "Windows App" = 1295203466;  # Removed - causes installation issues
  };

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
      AppleInterfaceStyle = "Dark";
      AppleKeyboardUIMode = 3;
    };
    
    dock = {
      orientation = "bottom";
      showhidden = true;
      mineffect = "scale";
      static-only = true;
      tilesize = 48;
      autohide = true;
      mru-spaces = false;
      show-recents = false;
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
      TrackpadRightClick = true;
    };
    
    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      _FXShowPosixPathInTitle = true;
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