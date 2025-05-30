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
  
  # Set primary user for nix-darwin (required for certain options)
  system.primaryUser = username;
  
  # Cấu hình Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Fix nixbld group GID
  ids.gids.nixbld = 350;
  
  # Cài đặt môi trường macOS cơ bản
  environment.systemPackages = with pkgs; [

  ];
  
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