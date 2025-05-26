{ config, lib, pkgs, ... }:

{
  # Cấu hình WSL
  wsl = {
    enable = true;
    defaultUser = "rnd";
    startMenuLaunchers = true;
    
    # WSL2 tốt hơn cho hầu hết trường hợp sử dụng
    wslFeatures = {
      enabled = true;
    };
    
    # Tích hợp với hệ thống Windows
    interop = {
      enabled = true;
      appendWindowsPath = true;
    };
    
    # Tự động mount các đĩa Windows
    automountOptions = "metadata,umask=22,fmask=11";
  };
  
  # Các tùy chỉnh bổ sung cho WSL
  environment.systemPackages = with pkgs; [
    wslu  # Tiện ích WSL
    wget
    curl
    git
  ];
  
  # Bật một số tùy chọn hữu ích cho WSL
  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ]; # DNS tốt hơn
  networking.firewall.enable = false; # Không cần tường lửa trong WSL
  time.timeZone = "Asia/Ho_Chi_Minh";
  
  # Vô hiệu hóa các dịch vụ không cần thiết trong WSL
  services.xserver.enable = false;
  services.pipewire.enable = false;
  services.printing.enable = false;
}