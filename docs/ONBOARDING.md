# Onboarding — Hướng dẫn setup cho team member mới

## Yêu cầu

- macOS, NixOS, Ubuntu, hoặc WSL
- Git đã cài sẵn

## Bước 1: Clone repo

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
```

## Bước 2: Tạo profile cá nhân

```bash
./scripts/add-user.sh <tên-bạn>
```

Script sẽ copy template profile và mở file để bạn sửa:
- **Git identity**: `userName` và `userEmail` (BẮT BUỘC)
- **ZSH plugins**: Thêm `"macos"`, `"ubuntu"`, hoặc `"wsl"` tùy OS
- **Packages riêng**: Thêm vào `home.packages`

## Bước 3: Thiết lập khóa bảo mật (Age Key cho SOPS)

Dự án này sử dụng SOPS mã hóa bí mật. Bạn BẮT BUỘC phải tạo một Age key để giải mã:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Sau khi tạo, lấy **Public Key** (dòng bắt đầu bằng `# public key: ...`) và gửi cho Team Lead để họ thêm vào file `.sops.yaml` ở gốc dự án. Nếu không làm bước này, bạn sẽ bị lỗi khi cài đặt.

## Bước 3: Tạo machine config

```bash
./scripts/add-machine.sh <hostname> <os>
# <os>: darwin | nixos | ubuntu | wsl
```

## Bước 4: Thêm entry vào `flake.nix`

Mở `flake.nix` và thêm entry mới vào section tương ứng:

**macOS:**
```nix
darwinConfigurations = {
  # ... existing entries ...
  <hostname> = mkDarwin {
    hostname = "<hostname>";
    username = "<tên-bạn>";
    system = "aarch64-darwin";  # Hoặc "x86_64-darwin" cho Intel Mac
  };
};
```

**NixOS:**
```nix
nixosConfigurations = {
  <hostname> = mkNixOS {
    hostname = "<hostname>";
    username = "<tên-bạn>";
  };
};
```

**Ubuntu:**
```nix
homeConfigurations = {
  "<tên-bạn>@<hostname>" = mkUbuntu {
    hostname = "<hostname>";
    username = "<tên-bạn>";
  };
};
```

## Bước 5: Bootstrap & Install

```bash
# Lần đầu (cài Nix, Homebrew, nix-darwin...)
./install.sh

# Lần sau (cập nhật)
./scripts/update.sh
```

## Bước 6: Setup Secrets (tùy chọn)

Xem [SECRETS.md](./SECRETS.md) để cấu hình SOPS/Age.

## Bước 7: Cấu hình AI IDE với 9Router

Hệ thống đã tự động cài đặt và chạy ngầm service `9router`. Nếu bạn sử dụng các AI IDE như **Cursor**, **Cline**, hay plugin gọi API LLM:
- Chuyển `Base URL` thành: `http://localhost:20128/v1`
- `9router` sẽ tự động route các request OpenAI-compatible đến model cục bộ hoặc API từ xa an toàn.

## Kiểm tra sức khỏe

```bash
./scripts/verify.sh
```

## Dev Shell

Khi muốn sửa code Nix trong repo này:

```bash
nix develop
# Có sẵn: nixfmt-rfc-style, nil (LSP), statix (linter), deadnix
```

## Quy tắc team

1. **Mọi PR đều phải pass CI** (`nix flake check` + `nix fmt --check`)
2. **Không dùng `--impure`** — tất cả configs phải hardcoded trong `flake.nix`
3. **Profile cá nhân**: Sửa trong `home/profiles/<tên-bạn>/`, KHÔNG sửa `base/`
4. **Thay đổi base**: Cần review từ team lead
