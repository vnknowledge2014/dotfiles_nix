{ config, lib, pkgs, ... }:

{
  wsl = {
    enable = true;
    defaultUser = "rnd";
    startMenuLaunchers = true;
    
    # Tự động mount các đĩa Windows
    automountOptions = "metadata,umask=22,fmask=11";
  };
  
  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  networking = {
    hostId = "8425e349";
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
    firewall.enable = false;
  };
  
  time.timeZone = "Asia/Ho_Chi_Minh";
  
  # Vô hiệu hóa các dịch vụ không cần thiết trong WSL
  services = {
    xserver.enable = false;
    pipewire.enable = false;
    printing.enable = false;
  };

  # Các tùy chỉnh bổ sung cho WSL
  environment.systemPackages = with pkgs; [
    wslu  # Tiện ích WSL
    wget
    curl
    git
  ];
}