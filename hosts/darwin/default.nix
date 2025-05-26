{ config, lib, pkgs, hostname, username, ... }:

{
  # Import các thành phần cấu hình theo thứ tự
  imports = [
    # Cấu hình macOS cơ bản
    ./base.nix
    
    # Cấu hình Homebrew
    ./homebrew.nix

    # Cấu hình cho XCode nếu có  
    ./xcode.nix
  ];
  
  # Thiết lập cơ bản
  networking.hostName = hostname;
  
  # Cấu hình Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Cài đặt môi trường macOS cơ bản
  environment.systemPackages = with pkgs; [
    coreutils
    gnugrep
    wget
    curl
    git
    jq
    zsh
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
  
  # Fix LaunchAgents permissions
  system.activationScripts.preActivation.text = ''
    echo "Fixing LaunchAgents directory permissions..."
    mkdir -p /Users/${username}/Library/LaunchAgents
    chown ${username}:staff /Users/${username}/Library/LaunchAgents
    chmod 755 /Users/${username}/Library/LaunchAgents
  '';
  
  # Phiên bản hệ thống
  system.stateVersion = 4;
}