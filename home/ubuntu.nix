{ config, lib, pkgs, system, inputs, hostname, username, ... }:

let
  # Check if machine-specific config exists
  machineConfigPath = ./profiles/${username}/machines/${hostname}.nix;
  hasMachineConfig = builtins.pathExists machineConfigPath;
in
{
  # Import các module cơ bản và machine-specific config nếu tồn tại
  imports = [ 
    ./modules/core
    ./modules/shell
    ./modules/dev/git.nix
    ./modules/editors
    ./modules/terminal
    ./profiles/${username}
    # Snap package management trên Ubuntu
    ../hosts/ubuntu/snapd.nix
  ] ++ lib.optional hasMachineConfig machineConfigPath;
  
  # Thông tin cơ bản
  home.username = username;
  home.homeDirectory = "/home/${username}";
  
  # Module enables — base profile đã bật hết, ở đây chỉ cần khai báo tối thiểu
  modules = {
    core.enable = true;
    dev.git.enable = true;
    editors.enable = true;
    terminal.enable = true;
  };
  
  # Phiên bản Home Manager
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  # Tự động thiết lập giới hạn ZFS ARC (16GB) nếu phát hiện máy có ZFS nhưng chưa cấu hình
  home.activation.zfs-arc-limit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d /sys/module/zfs ]; then
      if [ ! -f /etc/modprobe.d/zfs.conf ] || ! grep -q "zfs_arc_max" /etc/modprobe.d/zfs.conf 2>/dev/null; then
        echo -e "\n\e[1;33m[ZFS ARC Tuning] Phát hiện hệ thống có module ZFS nhưng chưa cấu hình giới hạn ARC.\e[0m"
        echo -e "\e[1;34mĐang tự động thiết lập vĩnh viễn giới hạn 16GB ZFS ARC vào /etc/modprobe.d/zfs.conf...\e[0m"
        
        # Thử ghi cấu hình và update initramfs bằng sudo
        if sudo sh -c 'echo "options zfs zfs_arc_max=17179869184" >> /etc/modprobe.d/zfs.conf && update-initramfs -u -k all'; then
          echo -e "\e[1;32m[ZFS ARC Tuning] Đã cấu hình giới hạn ZFS ARC 16GB thành công!\e[0m\n"
        else
          echo -e "\e[1;31m[ZFS ARC Tuning] Không thể thiết lập tự động do thiếu quyền sudo. Bạn hãy tự chạy lệnh sau:\e[0m"
          echo -e "  echo 'options zfs zfs_arc_max=17179869184' | sudo tee -a /etc/modprobe.d/zfs.conf && sudo update-initramfs -u -k all\n"
        fi
      fi
    fi
  '';
}
