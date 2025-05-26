# Dotfiles Đa Nền Tảng

Dự án này cung cấp bộ cấu hình dotfiles đa nền tảng, tự động phát hiện và thiết lập môi trường phù hợp cho NixOS, macOS, Ubuntu và WSL. Dự án được thiết kế để dễ dàng chia sẻ trong team và duy trì môi trường phát triển nhất quán.

## Tính Năng Chính

- **Tự động phát hiện hệ thống** - Tự động phát hiện và áp dụng cấu hình phù hợp
- **Hỗ trợ đa nền tảng** - NixOS, NixOS trên WSL, macOS và Ubuntu
- **Tích hợp liền mạch** - Nix, Homebrew, Home Manager và Snapd
- **Module hóa** - Các cấu hình được tổ chức thành module nhỏ, dễ tùy chỉnh
- **Động và mở rộng** - Dễ dàng thêm máy mới và người dùng mới
- **Một lệnh thiết lập** - Cài đặt và cấu hình toàn bộ hệ thống với một lệnh duy nhất

## Cài Đặt Nhanh

```bash
# Clone repository
git clone https://github.com/username/dotfiles.git
cd dotfiles

# Cài đặt tự động (phát hiện hệ thống và thiết lập)
./install.sh
```

## Cấu Trúc Dự Án

```
dotfiles/
├── flake.nix                    # Cấu hình flake chính
├── install.sh                   # Script cài đặt tự động
├── README.md                    # Tài liệu này
├── lib/                         # Thư viện tiện ích
│   └── default.nix              # Hàm tiện ích và phát hiện hệ thống
├── hosts/                       # Cấu hình theo máy
│   ├── common/                  # Cấu hình chung cho tất cả hệ thống
│   │   └── default.nix          # Cấu hình Nix và package cơ bản
│   ├── nixos/                   # Cấu hình NixOS
│   │   ├── common.nix           # Cấu hình chung cho NixOS
│   │   └── machines/            # Cấu hình theo máy cụ thể
│   │       └── legion/          # Ví dụ: cấu hình cho máy Legion
│   ├── wsl/                     # Cấu hình WSL
│   │   └── default.nix          # Cấu hình NixOS trên WSL
│   ├── darwin/                  # Cấu hình macOS
│   │   ├── default.nix          # Entry point cho cấu hình Darwin
│   │   ├── base.nix             # Cấu hình cơ bản cho macOS
│   │   ├── homebrew.nix         # Cấu hình Homebrew
│   │   ├── xcode.nix            # Cấu hình XCode
│   │   └── machines/            # Cấu hình theo máy macOS
│   │       └── macbook/         # Ví dụ: cấu hình cho máy MacBook
│   └── ubuntu/                  # Cấu hình Ubuntu
│       └── snapd.nix            # Cấu hình Snapd
├── home/                        # Cấu hình Home Manager
│   ├── modules/                 # Các module cấu hình
│   │   ├── core/                # Cấu hình cốt lõi 
│   │   ├── dev/                 # Công cụ phát triển
│   │   │   └── git.nix          # Cấu hình Git
│   │   ├── shell/               # Cấu hình Shell
│   │   ├── editors/             # Cấu hình Editor
│   │   └── terminal/            # Cấu hình Terminal
│   ├── nixos.nix                # Entry cho NixOS
│   ├── darwin.nix               # Entry cho macOS
│   ├── ubuntu.nix               # Entry cho Ubuntu
│   ├── wsl.nix                  # Entry cho WSL
│   └── profiles/                # Hồ sơ người dùng
│       ├── rnd/                 # Profile cho user rnd
│       ├── mike/                # Profile cho user mike
│       └── template/            # Template để thêm người dùng mới
└── scripts/                     # Scripts hữu ích
    ├── add-user.sh              # Thêm người dùng mới
    └── add-machine.sh           # Thêm máy mới
```

## Hướng Dẫn Cài Đặt Chi Tiết

### NixOS

1. Clone repository:
   ```bash
   git clone https://github.com/username/dotfiles.git
   cd dotfiles
   ```

2. Cài đặt tự động:
   ```bash
   ./install.sh
   ```

3. Hoặc cài đặt thủ công:
   ```bash
   # Bật Nix flakes nếu chưa có
   sudo mkdir -p /etc/nix
   echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf

   # Xây dựng cấu hình
   sudo nixos-rebuild switch --flake .#hostname
   ```

### macOS

1. Clone repository:
   ```bash
   git clone https://github.com/username/dotfiles.git
   cd dotfiles
   ```

2. Cài đặt tự động:
   ```bash
   ./install.sh
   ```

3. Hoặc cài đặt thủ công:
   ```bash
   # Cài đặt Nix nếu chưa có
   sh <(curl -L https://nixos.org/nix/install) --daemon
   
   # Cài đặt Homebrew nếu chưa có
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   
   # Cài đặt nix-darwin nếu chưa có
   nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
   ./result/bin/darwin-installer
   
   # Xây dựng cấu hình
   darwin-rebuild switch --flake .#hostname
   ```

### Ubuntu

1. Clone repository:
   ```bash
   git clone https://github.com/username/dotfiles.git
   cd dotfiles
   ```

2. Cài đặt tự động:
   ```bash
   ./install.sh
   ```

3. Hoặc cài đặt thủ công:
   ```bash
   # Cài đặt các gói cần thiết
   sudo apt update
   sudo apt install -y curl git build-essential
   
   # Cài đặt Nix nếu chưa có
   sh <(curl -L https://nixos.org/nix/install) --daemon
   
   # Bật flakes
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
   
   # Cài đặt home-manager
   nix-shell -p nixFlakes --run "nix run github:nix-community/home-manager/release-24.11 -- switch --flake .#username@hostname"
   ```

### NixOS trên WSL

1. Clone repository:
   ```bash
   git clone https://github.com/username/dotfiles.git
   cd dotfiles
   ```

2. Cài đặt tự động:
   ```bash
   ./install.sh
   ```

3. Hoặc cài đặt thủ công:
   ```bash
   # Bật flakes
   sudo mkdir -p /etc/nix
   echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
   
   # Xây dựng cấu hình
   sudo nixos-rebuild switch --flake .#wsl
   ```

## Quản Lý Hệ Thống và Người Dùng Động

### Phát Hiện Hệ Thống

Dự án tự động phát hiện hostname, username và hệ điều hành. Bạn có thể ghi đè bằng biến môi trường:

```bash
HOSTNAME=custom-hostname USERNAME=custom-username ./install.sh
```

### Thêm Người Dùng Mới

1. Sử dụng script:
   ```bash
   ./scripts/add-user.sh new-username "Full Name" "email@example.com"
   ```

2. Hoặc thủ công:
   ```bash
   # Tạo thư mục profile mới
   cp -r home/profiles/template home/profiles/new-username
   
   # Chỉnh sửa thông tin cá nhân
   vim home/profiles/new-username/default.nix
   ```

### Thêm Máy Mới

1. Sử dụng script:
   ```bash
   ./scripts/add-machine.sh new-hostname nixos
   ```

2. Hoặc thủ công cho NixOS:
   ```bash
   # Tạo thư mục cấu hình mới
   mkdir -p hosts/nixos/machines/new-hostname
   
   # Tạo cấu hình phần cứng
   nixos-generate-config --dir hosts/nixos/machines/new-hostname
   ```

3. Hoặc thủ công cho macOS:
   ```bash
   # Tạo thư mục cấu hình mới
   mkdir -p hosts/darwin/machines/new-hostname
   
   # Tạo file cấu hình
   cp hosts/darwin/machines/template/default.nix hosts/darwin/machines/new-hostname/default.nix
   ```

## Tùy Chỉnh Cấu Hình

### Cấu Hình Git

Cấu hình Git chung được định nghĩa trong `home/modules/dev/git.nix`:

```nix
{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.dev.git;
in {
  options.modules.dev.git = {
    enable = mkEnableOption "Enable git configuration";
    
    aliases = mkOption {
      type = types.attrsOf types.str;
      default = {
        co = "checkout";
        ci = "commit";
        st = "status";
        br = "branch";
        hist = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";
      };
      description = "Git aliases";
    };
    
    extraConfig = mkOption {
      type = types.attrsOf types.anything;
      default = {
        init.defaultBranch = "main";
        pull.rebase = false;
      };
      description = "Extra git configuration";
    };
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      aliases = cfg.aliases;
      extraConfig = cfg.extraConfig;
    };
  };
}
```

Cấu hình Git cá nhân được định nghĩa trong profile của từng người dùng:

```nix
# Trong home/profiles/username/default.nix
programs.git = {
  userName = "Your Name";
  userEmail = "your.email@example.com";
};
```

### Thêm Package Riêng

Thêm package riêng trong profile cá nhân:

```nix
# Trong home/profiles/username/default.nix
home.packages = with pkgs; [
  # Thêm các package riêng tại đây
  nodejs
  yarn
  docker
];
```

### Tùy Chỉnh Homebrew trên macOS

Cấu hình Homebrew trong file cấu hình máy macOS:

```nix
# Trong hosts/darwin/machines/macbook/default.nix
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
  
  # Danh sách đầy đủ
  brews = [
    "mas"      # Mac App Store CLI
    "python"
    "go"
    "node" 
    "yarn"
  ];
  
  casks = [
    "google-chrome"
    "firefox"
    "visual-studio-code"
    "docker"
  ];
  
  masApps = {
    "Xcode" = 497799835;
  };
};
```

### Tùy Chỉnh Snapd trên Ubuntu

Thêm package Snap trong `home/ubuntu.nix`:

```nix
# Tích hợp với snapd
home.activation.snapPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
  if command -v snap > /dev/null 2>&1; then
    echo "Cài đặt các gói snap..."
    
    # Danh sách các gói snap
    PACKAGES=(${lib.concatStringsSep " " (map (x: "\"${x}\"") (["code" "spotify" "slack"] ++ (config.extraSnaps or [])))})
    
    for pkg in "''${PACKAGES[@]}"; do
      if ! snap list | grep -q "^$pkg"; then
        echo "Đang cài đặt $pkg..."
        sudo snap install $pkg
      fi
    done
  fi
'';
```

## Module Hóa và Tùy Biến

Hệ thống dotfiles này được thiết kế theo mô hình module hóa, giúp dễ dàng tùy biến và mở rộng:

1. **Module Core**: Cấu hình cốt lõi và package cơ bản
2. **Module Shell**: Cấu hình ZSH, oh-my-zsh, và shell aliases
3. **Module Dev**: Công cụ phát triển, bao gồm Git
4. **Module Editors**: Cấu hình editor như VSCode, Neovim
5. **Module Terminal**: Cấu hình terminal emulator

Mỗi module có thể được bật/tắt và tùy chỉnh trong profile cá nhân:

```nix
# Trong home/profiles/username/default.nix
modules = {
  core = {
    enable = true;
    packages = with pkgs; [ ... ];
  };
  
  shell = {
    enable = true;
    zsh = {
      enable = true;
      ohmyzsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = [ "git" "docker" ];
      };
      aliases = {
        # Sử dụng lib.mkForce để ưu tiên hơn cấu hình mặc định
        ll = lib.mkForce "eza -l --icons";
        la = lib.mkForce "eza -la --icons";
      };
    };
  };
  
  dev.git.enable = true;
  editors.enable = true;
};
```

## Cập Nhật Hệ Thống

### NixOS

```bash
cd dotfiles
git pull
sudo nixos-rebuild switch --flake .#hostname
```

### macOS

```bash
cd dotfiles
git pull
darwin-rebuild switch --flake .#hostname
```

### Ubuntu

```bash
cd dotfiles
git pull
nix run home-manager/release-24.11 -- switch --flake .#username@hostname
```

## FAQ & Troubleshooting

### Nix flakes không hoạt động

Đảm bảo đã bật tính năng thử nghiệm:

```bash
# NixOS
sudo mkdir -p /etc/nix
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf

# macOS / Ubuntu
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
```

### Không tìm thấy host hoặc user

Kiểm tra cấu hình flake.nix và đảm bảo hostname và username khớp với cấu hình hoặc sử dụng cấu hình động.

### Xung đột Homebrew

Nếu gặp xung đột giữa Nix và Homebrew, đảm bảo đường dẫn đúng:

```bash
export PATH=/usr/local/bin:$PATH  # Homebrew Intel
# hoặc
export PATH=/opt/homebrew/bin:$PATH  # Homebrew Apple Silicon
```

### Lỗi trên Ubuntu

Đảm bảo đã cài đặt các gói tiên quyết:

```bash
sudo apt update
sudo apt install -y curl git build-essential
```

### Xung đột trong cấu hình shell aliases

Nếu gặp lỗi xung đột định nghĩa cho cùng một alias, sử dụng `lib.mkForce` để chỉ định ưu tiên:

```nix
aliases = {
  ll = lib.mkForce "eza -l --icons";
  la = lib.mkForce "eza -la --icons";
};
```

### Lỗi về nix.settings.auto-optimise-store

Nếu gặp lỗi về `nix.settings.auto-optimise-store`, hãy thay thế bằng cấu hình an toàn hơn:

```nix
nix = {
  settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # auto-optimise-store = true;  # Thiết lập gây lỗi, đã bị xóa
  };
  
  # Sử dụng thiết lập được khuyến nghị
  optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
};
```

### Không thể tìm thấy đường dẫn cho cấu hình máy

Đảm bảo bạn đã tạo cấu hình cho máy cụ thể trong thư mục tương ứng:

```bash
# Cho NixOS
mkdir -p hosts/nixos/machines/your-hostname

# Cho macOS
mkdir -p hosts/darwin/machines/your-hostname
```

## Đóng Góp

Vui lòng đóng góp và báo lỗi qua GitHub Issues hoặc gửi Pull Request.

## Giấy Phép

MIT License