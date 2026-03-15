# SYNC MACOS CONFIG TO UBUNTU

Hướng dẫn đồng bộ cấu hình giữa macOS và Ubuntu.

## Tổng Quan

**Tỷ lệ tương thích:** ~95% giống nhau, 5% khác biệt do platform.

## Sự Khác Biệt Chính

| Thành phần | macOS | Ubuntu |
|------------|-------|--------|
| Container | OrbStack | Docker Engine |
| Editor install | Homebrew cask | Deb package |
| Terminal | Ghostty (brew) | Ghostty (.deb) |
| Package manager | Nix + Homebrew | Nix + APT + Snap |
| DOCKER_HOST | `~/.orbstack/run/docker.sock` | `/var/run/docker.sock` |
| Home path | `/Users/{user}` | `/home/{user}` |

## Cấu Trúc Multi-Machine

```
home/profiles/{username}/
├── default.nix           # Config chung (chia sẻ macOS + Ubuntu)
└── machines/
    ├── macbook.nix       # Override cho macOS (OrbStack)
    └── ubuntu-pc.nix     # Override cho Ubuntu (Docker Engine)
```

### Ví dụ: machines/ubuntu-pc.nix

```nix
{ config, lib, pkgs, hostname, ... }:
{
  programs.zsh.initExtra = lib.mkAfter ''
    export DOCKER_HOST='unix:///var/run/docker.sock'
  '';
}
```

## Cài Đặt

### Ubuntu

```bash
# Clone repository
git clone https://github.com/vnknowledge2014/dotfiles_nix.git
cd dotfiles_nix

# Cài đặt với preset
./install.sh --preset all

# Hoặc interactive mode
./install.sh --interactive
```

### Sau cài đặt

```bash
# Logout/login để áp dụng docker group
# Sau đó verify
./scripts/verify.sh
```

## Những Gì Được Cài Trên Ubuntu

### Qua Nix/Home Manager
- ZSH + Oh-My-Zsh + Starship
- Neovim, Git config
- CLI tools (eza, bat, ripgrep, fd, fzf, jq, etc.)
- Tmux config
- FiraCode Nerd Font

### Qua install.sh
- Docker Engine + docker-compose
- Ghostty terminal (.deb)
- Antigravity (tar.gz → /opt)
- asdf + programming languages
- Flatpak + Podman Desktop

### Qua Snap
- Spotify

## Preset Ngôn Ngữ

```bash
# Xem danh sách
./asdf-vm/planguage.sh --list-presets

# Presets có sẵn:
# - minimal: Python only
# - web-developer: Node, Bun, Deno, Python
# - data-scientist: Python, UV, Julia
# - systems-developer: Zig, Go, Rust
# - all: Tất cả
```

## Kiểm Tra Sau Cài Đặt

```bash
# Health check
./scripts/verify.sh

# Hoặc thủ công
docker --version && docker ps
asdf list
nvim --version
starship --version
ghostty --version
```

## Troubleshooting

### Docker không chạy
```bash
# Kiểm tra group
groups | grep docker
# Nếu không có, logout/login lại
```

### asdf không tìm thấy
```bash
# Script sẽ hỏi link download
# Tải từ: https://github.com/asdf-vm/asdf/releases
```

### Python/Erlang build failed
```bash
# Cài build dependencies
sudo apt install -y build-essential autoconf libssl-dev libncurses-dev \
  libreadline-dev zlib1g-dev libbz2-dev libsqlite3-dev libffi-dev liblzma-dev

# Chạy lại
./asdf-vm/planguage.sh --preset all
```

## Cập Nhật

```bash
# Auto-update từ remote
./scripts/update.sh
```
