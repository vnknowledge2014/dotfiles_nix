# Dotfiles Đa Nền Tảng (Team-Ready Architecture)

Dự án cấu hình dotfiles đa nền tảng được thiết kế đặc biệt cho **môi trường Team (Nhiều thành viên)**. Cấu trúc tuân thủ nghiêm ngặt nguyên tắc **Pure Evaluation** của Nix Flakes, đảm bảo tính tái lập (reproducibility) 100% trên CI/CD.

Hỗ trợ: **NixOS, macOS, Ubuntu, và WSL**.

## Tính Năng Nổi Bật (SOTA 2026)

- **Pure Nix Flakes**: Không phụ thuộc vào biến môi trường (`$USER`, `$HOSTNAME`), chạy hoàn hảo trên GitHub Actions.
- **Multi-tenant / Multi-machine**: Mỗi thành viên tự quản lý profile cá nhân (`home/profiles/<user>/`) mà không xung đột với base chung.
- **CI/CD Tích Hợp**: Tự động kiểm tra flake (`nix flake check`), format (`nixfmt-rfc-style`), và lint (`statix`, `deadnix`) trên mỗi PR.
- **Secrets Management (SOPS + Age)**: Mã hóa API keys, passwords an toàn trong Git. Hỗ trợ 2 phân cấp: Shared Secrets (cho cả team) và Per-User Secrets.
- **Dev Shell (`nix develop`)**: Môi trường phát triển chuẩn hóa với linter và formatter tích hợp.

## 🚀 Dành cho Thành Viên Mới (Onboarding)

Nếu bạn mới tham gia team, vui lòng đọc Hướng dẫn chi tiết tại:
👉 **[Tài liệu Onboarding](docs/ONBOARDING.md)**

Các bước cơ bản:
1. Tạo profile: `./scripts/add-user.sh <tên-bạn>`
2. Thêm máy: `./scripts/add-machine.sh <hostname> <os>`
3. Thêm cấu hình vào `flake.nix`
4. Cài đặt: `./install.sh`

## 🔐 Quản Lý Secrets

Team sử dụng SOPS và Age để mã hóa dữ liệu nhạy cảm. 
👉 **[Xem Runbook Quản Lý Secrets](docs/SECRETS.md)**

## Cấu Trúc Dự Án

```
dotfiles/
├── flake.nix                    # Cấu hình flake chính (HARDCODED Hosts & Users)
├── install.sh                   # Script cài đặt bootstrap
├── docs/                        # Tài liệu cho team
│   ├── ONBOARDING.md
│   └── SECRETS.md
├── secrets/                     # Chứa các file YAML đã mã hóa bởi SOPS
│   ├── shared/                  # Bí mật chung của team
│   └── users/                   # Bí mật cá nhân
├── home/
│   ├── darwin.nix, ubuntu.nix, nixos.nix, wsl.nix # OS Entry points
│   └── profiles/
│       ├── base/                # Cấu hình chuẩn của toàn công ty/team
│       └── <username>/          # Override riêng của từng cá nhân
├── hosts/                       # Cấu hình mức system/hardware
│   ├── darwin/
│   ├── nixos/
│   └── wsl/
└── .github/workflows/           # CI/CD Pipelines
```

## Lệnh Hữu Ích

### Dev Shell
Mở môi trường phát triển (có sẵn linter, formatter):
```bash
nix develop
```

### Format Code
Tự động format tất cả file `.nix` theo chuẩn RFC 166:
```bash
nix fmt
```

### Health Check (Doctor)
Kiểm tra sức khỏe hệ thống và tìm lỗi:
```bash
./scripts/verify.sh
```

### Auto-Update
Cập nhật git, inputs, rebuild system và clean up:
```bash
./scripts/update.sh
```

## Preset Ngôn Ngữ Lập Trình (asdf-vm)

| Preset | Ngôn ngữ | Rustup |
|--------|----------|--------|
| `minimal` | Python | ❌ |
| `web-developer` | Node.js, Bun, Deno, Python | ❌ |
| `data-scientist` | Python, UV, Julia | ❌ |
| `devops-engineer` | Python, Go, Node.js | ❌ |
| `mobile-developer` | Flutter, Node.js | ❌ |
| `systems-developer` | Zig, Go | ✅ |
| `functional-developer` | Haskell, OCaml, Elixir, Gleam | ❌ |
| `all` | Tất cả ngôn ngữ | ✅ |

Cài đặt bằng cách:
```bash
./install.sh --preset web-developer --add rust,go
```

## Giấy Phép

MIT License