# Threat Model: Dotfiles Đa Nền Tảng

**Mode:** bootstrap
**Date:** 2026-07-30
**Scope:** Toàn bộ cấu hình Nix (flake.nix, modules, profiles), script cài đặt (install.sh, update.sh), quản lý bí mật (SOPS) và các dịch vụ ngầm (9router). Không bao gồm cấu hình phần cứng cụ thể hay repository phụ thuộc (như nixpkgs).

## 1. System Context
Dự án dotfiles đa nền tảng (macOS, NixOS, Ubuntu, WSL) dành cho team. Quản lý cấu hình bằng Nix Flakes đảm bảo Pure Evaluation. Quản lý bí mật bằng SOPS + Age (Shared và Per-User secrets). Hỗ trợ các services ngầm như `9router` proxy LLM API.

## 2. Assets
| Asset | Sensitivity | Notes |
|-------|-------------|-------|
| SOPS Age Private Keys | HIGH | Khóa giải mã lưu trên máy cá nhân (`~/.config/sops/age/keys.txt`). Nếu lộ, toàn bộ bí mật bị giải mã. |
| Decrypted Secrets (API Keys) | HIGH | Các token (GitHub, OpenAI) được giải mã vào bộ nhớ hoặc file tạm. |
| Shell Configuration | MEDIUM | Cấu hình ZSH/bash/aliases. Bị thay đổi có thể dẫn tới thực thi mã độc. |
| System Services (9router, sshd) | MEDIUM | Các dịch vụ chạy ngầm, nếu bị tấn công có thể rò rỉ dữ liệu hoặc DoS. |

## 3. Entry Points & Trust Boundaries
| Entry Point | Protocol | Caller trust | Notes |
|-------------|----------|--------------|-------|
| Git Pull / Flake Inputs | HTTPS/SSH | Low | Bất kỳ thay đổi nào từ origin repository hoặc third-party flakes (nixpkgs). |
| `install.sh` / `update.sh` | Bash | Medium | File thực thi cục bộ. Cần đảm bảo quyền thực thi và nguồn gốc an toàn. |
| `9router` API | HTTP | High | Cổng `localhost:20128/v1` chỉ cho phép truy cập từ máy nội bộ (local). |
| Môi trường CI/CD | GitHub Actions | Low | Các workflow chạy tự động trên mỗi PR (`nix flake check`). |

## 4. Threats
| ID | Threat | Actor | Surface | Asset | Likelihood (1-5) | Impact (1-5) | L×I | Status | Controls |
|----|--------|-------|---------|-------|-----------------|--------------|-----|--------|----------|
| T-01 | Lộ lọt Secret do commit nhầm file clear-text | Internal | Git | Secrets | 3 | 5 | 15 | Open | `.gitignore`, SOPS pre-commit hook (cần cấu hình). |
| T-02 | Chèn mã độc qua Flake Inputs (Supply Chain) | External | flake.nix | Shell Config | 2 | 5 | 10 | Mitigated | Nix khóa hash trong `flake.lock`. |
| T-03 | Thực thi mã từ xa qua lỗ hổng `9router` | External | 9router | System | 2 | 4 | 8 | Open | Chỉ bind vào `127.0.0.1`, dùng Rust/memory-safe language. |
| T-04 | Lộ Age Private Key do malware/local access | Local | Filesystem | Age Keys | 2 | 5 | 10 | Mitigated | Phân quyền 0600 cho thư mục `~/.config/sops`. |
| T-05 | Đệ quy vô hạn gây Crash CI/CD | Internal | Nix Eval | CI/CD | 4 | 2 | 8 | Mitigated | Đã thiết kế Pure Evaluation không biến môi trường. |

## 5. Deprioritized Threats
- **Tấn công Man-in-the-Middle (MitM) khi tải Nix packages:** Nixpkgs dùng HTTPS và kiểm tra mã băm SHA256 cho mọi gói tải về, do đó rủi ro này được vô hiệu hóa ở cấp độ thiết kế của Nix.
- **Tấn công cạn kiệt tài nguyên (OOM) bởi ZFS ARC:** Đã được xử lý triệt để qua việc giới hạn ARC max trên Linux.

## 6. Open Questions
- Team có đang sử dụng pre-commit hook (như `detect-secrets`) để chặn việc vô tình commit các file chưa được SOPS mã hóa không?
- Source code của `9router` có được scan lỗ hổng thường xuyên không, vì nó chạy dạng service ngầm?

## 7. Recommended Mitigations
1. **Thiết lập Pre-commit Hook:** Cấu hình `git hooks` (hoặc `lefthook`) để chạy `sops` check hoặc `detect-secrets` trước khi commit, ngăn chặn Lộ lọt Secret (T-01).
2. **Hardening 9router:** Xác minh lại bind address của 9router đảm bảo nó CHỈ nghe trên `127.0.0.1` và không lọt ra mạng ngoài.
3. **Audit Age Key Permissions:** Viết một script nhỏ trong `verify.sh` để kiểm tra phân quyền của `~/.config/sops` (phải là 0700/0600).
