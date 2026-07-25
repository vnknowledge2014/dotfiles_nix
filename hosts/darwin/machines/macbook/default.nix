{ config, lib, pkgs, ... }:

let
  # Đổi thành true để cài đặt Krunkit (cho phép Colima chạy AI Models bằng GPU)
  enableColimaAI = false;
in
{
  # Import cấu hình darwin chung
  imports = [];


  # Các cấu hình đặc thù cho máy macbook
  nixpkgs.config = {
    allowUnfree = true;
  };

  # Cài đặt các gói đặc thù cho máy này
  environment.systemPackages = with pkgs; [
    # Thêm các gói riêng cho máy macbook
  ];

  # Cấu hình Homebrew
  # Machine-specific Homebrew config
  extraTaps = if enableColimaAI then [
    "slp/krunkit"
    "quarkdown-labs/quarkdown"
    "anomalyco/tap"
  ] else [
    "quarkdown-labs/quarkdown"
    "anomalyco/tap"
  ];
  
  extraBrews = [
    # CLI tools
    "atuin"
    "yazi"
    "lazygit"
    "lazydocker"
    "btop"
    "ast-grep"
    "tree-sitter"
    "gh"
    
    # Kubernetes
    "kubernetes-cli"
    "k9s"
    "kind"
    "helm"
    
    # Container (Colima)
    "colima"
    "docker"
    "docker-compose"
    "docker-buildx"
    "docker-credential-helper"
    "incus"
    
    # Media
    "mpv"
    "ffmpeg-full"
    "yt-dlp"
    
    # Dev tools
    "asdf"
    "fnm"
    "posting"
    "gnupg"
    "smartmontools"
    "tesseract"
    "imagemagick"
    "cmake"
    "llama.cpp"
    
    # Build dependencies
    "pkg-config"
    "openssl@3"
    "librdkafka"
    "zlib"
    "p7zip"
    "pkgconf"
    "unar"
    
    # Utilities
    "quarkdown-labs/quarkdown/quarkdown"
    
    # Sync Additions
    "anomalyco/tap/opencode/opencode"
    "cocoapods"
    "llvm"
    "llvm@14"
    "llvm@15"
  ] ++ lib.optionals enableColimaAI [
    "krunkit"
  ];

  extraCasks = [
    # Editors & Dev
    "antigravity"
    "antigravity-ide"
    "antigravity-cli"
    "trae"
    "zed"
    "gitbutler"
    "postman"
    "apidog"
    
    # Browsers
    "brave-browser"
    "arc"
    "zen"
    
    # Terminal & Fonts
    "ghostty"
    "font-fira-code-nerd-font"
    
    # Android
    "android-commandlinetools"
    
    # Utilities
    "gotiengviet"
    "cloudflare-warp"
    "localsend"
    "rustdesk"
    "ollama-app"
    "iina"
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


  # Các thiết lập khác
  users.users.mike = {
    name = "mike";
    home = "/Users/mike";
  };

}