# Secrets Management — SOPS + Age

## Tổng quan

Repo này dùng [SOPS](https://github.com/getsops/sops) + [Age](https://age-encryption.org/) để mã hóa secrets (API keys, tokens, passwords...) trực tiếp trong Git.

- **Secrets chung** (`secrets/shared/`): Tất cả team members đều giải mã được
- **Secrets riêng** (`secrets/users/<tên>/`): Chỉ người đó giải mã được

## Setup lần đầu

### 1. Tạo Age keypair

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Output sẽ in ra public key dạng:
```
# created: 2026-05-24T00:00:00+07:00
# public key: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AGE-SECRET-KEY-1xxxx...
```

### 2. Gửi PUBLIC KEY cho team lead

Gửi dòng `age1xxx...` (KHÔNG gửi secret key `AGE-SECRET-KEY-1xxx`!) cho team lead qua kênh bảo mật.

### 3. Team lead thêm key vào `.sops.yaml`

Team lead sẽ:
1. Thêm public key vào `.sops.yaml`
2. Re-encrypt existing secrets: `sops updatekeys secrets/shared/*.yaml`
3. Commit & push

### 4. Pull & test

```bash
git pull
sops -d secrets/shared/api-keys.yaml  # Phải giải mã thành công
```

## Workflow hàng ngày

### Tạo secret mới

```bash
# Secret chung
sops secrets/shared/api-keys.yaml

# Secret riêng
mkdir -p secrets/users/$(whoami)
sops secrets/users/$(whoami)/tokens.yaml
```

SOPS sẽ mở editor (mặc định `$EDITOR`). Viết YAML bình thường:

```yaml
github_token: ghp_xxxxxxxxxxxx
openai_api_key: sk-xxxxxxxxxxxx
```

Save & quit — SOPS tự mã hóa values, giữ nguyên keys.

### Giải mã

```bash
# Xem nội dung
sops -d secrets/shared/api-keys.yaml

# Export ra biến môi trường
set -a; source <(sops -d --output-type dotenv secrets/shared/api-keys.yaml); set +a
```

### Sửa secret có sẵn

```bash
sops secrets/shared/api-keys.yaml  # Mở editor, sửa, save
```

## Quy tắc bảo mật

1. **KHÔNG BAO GIỜ** commit `~/.config/sops/age/keys.txt` vào Git
2. **KHÔNG** gửi secret key qua Slack/email — chỉ gửi public key
3. File `.sops.yaml` chỉ chứa **public keys** — an toàn để commit
4. Backup secret key ở nơi an toàn (password manager, USB encrypted)
5. Nếu mất secret key: tạo key mới, team lead re-encrypt
