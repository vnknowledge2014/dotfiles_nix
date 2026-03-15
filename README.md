# Dotfiles Đa Nền Tảng

Dự án cung cấp bộ cấu hình dotfiles đa nền tảng với các tính năng:

- **Tự động phát hiện hệ thống** - NixOS, macOS, Ubuntu, WSL
- **Preset System** - 8 preset ngôn ngữ lập trình (minimal → all)
- **Multi-machine per user** - 1 user, nhiều máy, mỗi máy config riêng
- **Health Check & Auto-Update** - Giám sát và cập nhật tự động

## Cài Đặt Nhanh

```bash
# Clone và cài đặt
git clone https://github.com/vnknowledge2014/dotfiles_nix.git
cd dotfiles_nix

# Cài đặt với interactive mode
./install.sh --interactive

# Hoặc với preset cụ thể
./install.sh --preset web-developer
./install.sh --preset all
```

## Preset Ngôn Ngữ

| Preset | Ngôn ngữ | Rustup |
|--------|----------|--------|
| `minimal` | Python | ❌ |
| `web-developer` | Node.js, Bun, Deno, Python | ❌ |
| `data-scientist` | Python, UV, Julia | ❌ |
| `devops-engineer` | Python, Go, Node.js | ❌ |
| `mobile-developer` | Flutter, Node.js | ❌ |
| `systems-developer` | Zig, Go | ✅ |
| `functional-developer` | Haskell, OCaml, Elixir, Erlang, Gleam, PureScript | ❌ |
| `all` | Tất cả ngôn ngữ | ✅ |

```bash
# Xem chi tiết presets
./asdf-vm/planguage.sh --list-presets

# Cài preset + thêm ngôn ngữ
./install.sh --preset web-developer --add rust,go
```

## Cấu Trúc Dự Án

```
dotfiles/
├── flake.nix                    # Cấu hình flake chính
├── install.sh                   # Script cài đặt (hỗ trợ --preset, --interactive)
├── versions.json                # Quản lý version tools (Antigravity, Ghostty)
├── asdf-vm/
│   ├── plugins.json             # Unified: asdf + rustup + presets
│   └── planguage.sh             # Script cài ngôn ngữ
├── home/
│   ├── darwin.nix               # Entry cho macOS
│   ├── ubuntu.nix               # Entry cho Ubuntu
│   ├── nixos.nix                # Entry cho NixOS
│   └── profiles/
│       └── {username}/
│           ├── default.nix      # Config chung của user
│           └── machines/        # Config riêng từng máy
│               └── {hostname}.nix
├── scripts/
│   ├── verify.sh                # Health check
│   ├── update.sh                # Auto-update
│   ├── add-user.sh              # Thêm user mới
│   └── add-machine.sh           # Thêm máy mới
└── hosts/
    ├── darwin/machines/         # Config macOS machines
    └── nixos/machines/          # Config NixOS machines
```

## Multi-Machine Per User

Mỗi user có thể có config khác nhau cho từng máy:

```
home/profiles/mike/
├── default.nix           # Config chung (shell, git, editor...)
└── machines/
    ├── macbook.nix       # Override cho MacBook (OrbStack DOCKER_HOST)
    └── ubuntu-pc.nix     # Override cho Ubuntu PC (Docker Engine)
```

System tự động detect hostname và import machine config tương ứng.

## Scripts Tiện Ích

### Health Check
```bash
./scripts/verify.sh
# Kiểm tra: Nix, Shell, Git, asdf, Rust, Docker, Editors, Terminal
```

### Auto-Update
```bash
./scripts/update.sh
# Tự động: git pull → handle conflicts → rebuild → verify
```

## Các Tính Năng Mới (Phase 7+)

### 🔐 Secrets Management
Sử dụng **SOPS** & **Age** để mã hóa secrets.
- Config: `.sops.yaml`
- Key location: `~/.config/sops/age/keys.txt`
- Giải mã tự động qua module `secrets`.

### 🏥 Dotfiles Doctor
Script kiểm tra sức khỏe hệ thống và đề xuất sửa lỗi:
```bash
./scripts/verify.sh
```

### 🚀 Remote Deploy (Mới)
Deploy dotfiles lên máy khác qua SSH:
```bash
./scripts/remote-deploy.sh user@host preset_name
```

### 🔙 System Rollback
Khôi phục cấu hình về phiên bản trước (Nix Generation):
```bash
./scripts/rollback.sh
```

## Tools Được Cài Đặt

### Editors
- **Antigravity** - AI-powered code editor:
  - **macOS**: Cài vào `/Applications` (via `install.sh`).
  - **Ubuntu/NixOS**: Quản lý native qua **Nix Module** (`home-manager` / `nixos-rebuild`).
  - **Config**: Declarative alias/path setup trong `macbook.nix` (macOS).
- **Neovim** - Terminal editor.

### File Systems
- **OpenZFS**:
  - **macOS**: Cài qua Homebrew Cask `openzfs`.
  - **Ubuntu**: Cài `zfsutils-linux`.
  - **NixOS**: Enable `boot.supportedFilesystems = ["zfs"]` (Yêu cầu set `networking.hostId` trong machine config).

### Thêm User Mới

```bash
./scripts/add-user.sh alice "Alice" "alice@example.com"
# Tạo profile mới từ template
```

## Cấu Hình Machine-Specific

Tạo file `home/profiles/{username}/machines/{hostname}.nix`:

```nix
{ config, lib, pkgs, hostname, ... }:
{
  # Docker runtime cho máy này
  programs.zsh.initExtra = lib.mkAfter ''
    export DOCKER_HOST='unix:///path/to/docker.sock'
  '';
  
  # Packages riêng cho máy này
  home.packages = with pkgs; [ some-machine-specific-tool ];
}
```

## Cập Nhật Version Tools

Edit `versions.json` để cập nhật URL cho Antigravity, Ghostty:

```json
{
  "tools": {
    "antigravity": {
      "version": "1.13.3",
      "darwin-arm": "https://...",
      "darwin-x64": "https://...",
      "linux": "https://..."
    }
  }
}
```

## FAQ

### Preset nào nên chọn?
- **Web developer**: `web-developer` (Node.js, Python, Deno, Bun)
- **Mobile dev**: `mobile-developer` (Flutter, Node.js)
- **Systems/Embedded**: `systems-developer` (Zig, Go, Rust)
- **Không biết chọn gì**: `all` (cài tất cả)

### Làm sao để thêm ngôn ngữ vào preset?
```bash
./install.sh --preset web-developer --add rust,go
```

### Machine config không được load?
Kiểm tra hostname khớp với tên file:
```bash
hostname -s  # Phải khớp với tên file trong machines/
```

## Giấy Phép

MIT License