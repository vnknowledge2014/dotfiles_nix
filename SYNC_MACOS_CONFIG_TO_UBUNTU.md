# SYNC MACOS CONFIG TO UBUNTU

Tài liệu chi tiết về việc đồng bộ cấu hình từ macOS sang Ubuntu.

**Mục tiêu:** Đưa 100% cấu hình từ macOS sang Ubuntu, chỉ thay thế những gì không tương thích.

**Tỷ lệ tương thích:** ~95% giống nhau, 5% cần điều chỉnh.

---

## KIẾN TRÚC MỚI (ĐÃ CẬP NHẬT)

### Nguyên tắc thiết kế:
1. **install.sh**: Xử lý TẤT CẢ package installation (APT, Snap, Flatpak, Docker)
2. **ubuntu.nix**: CHỈ chứa cấu hình Home Manager cơ bản
3. **profile/rnd/default.nix**: Cấu hình user (shell, editor, packages từ Nix)

### Lý do thay đổi:
- Home Manager activation scripts gây conflict và khó debug
- VSCode từ Nix không chạy được trên Ubuntu Desktop
- Snap/Flatpak cần được cài đặt sau khi Home Manager hoàn tất
- Docker cần setup repository trước khi cài đặt

---

## PHÂN TÍCH TƯƠNG THÍCH

### 1. HOME MANAGER MODULES (100% Tương Thích)

| Module | macOS | Ubuntu | Hành Động |
|--------|-------|--------|-----------|
| `modules/core` | ✅ | ✅ | Copy nguyên xi |
| `modules/shell` | ✅ | ✅ | Copy nguyên xi |
| `modules/dev/git.nix` | ✅ | ✅ | Copy nguyên xi |
| `modules/editors` | ✅ | ✅ | Copy nguyên xi |
| `modules/terminal` | ✅ | ✅ | Copy nguyên xi |

---

### 2. SHELL CONFIGURATION

#### A. ZSH + Oh-My-Zsh (95% Tương Thích)
- Plugins: `["git" "macos" "docker"]` → `["git" "ubuntu" "docker"]`

#### B. Starship Prompt (100% Tương Thích)
Copy toàn bộ cấu hình

#### C. Shell Aliases (100% Tương Thích)
Copy nguyên xi

---

### 3. TERMINAL & MULTIPLEXER

#### A. Tmux (100% Tương Thích)
Copy cấu hình và file .tmux.conf

#### B. Terminal Emulator

| macOS | Ubuntu | Cài Qua |
|-------|--------|---------|
| Ghostty | Ghostty | .deb package (install.sh) |
| Wezterm | Wezterm | Nix |

---

### 4. EDITORS & IDE

#### A. Neovim (100% Tương Thích)
Không cần thay đổi

#### B. VSCode

**Thay đổi quan trọng:**
- macOS: Cài qua Nix (quản lý extensions/settings)
- Ubuntu: Cài qua Snap (--classic) vì Nix version không chạy được
- Extensions và settings: Cấu hình trong profile nhưng disabled
- Keybindings: `cmd` → `ctrl`

---

### 5. CONTAINER & ORCHESTRATION

#### A. Container Runtimes

| Công Cụ | macOS | Ubuntu | Cài Qua |
|---------|-------|--------|---------|
| OrbStack | ✅ | ❌ | - |
| Docker Engine | ❌ | ✅ | APT (install.sh) |
| Podman | ✅ | ✅ | Nix |

**DOCKER_HOST:**
```bash
# macOS
export DOCKER_HOST='unix:///Users/mike/.obstack/run/docker.sock'

# Ubuntu
export DOCKER_HOST='unix:///var/run/docker.sock'
```

#### B. Container GUI/TUI

| Công Cụ | macOS | Ubuntu | Cài Qua |
|---------|-------|--------|---------|
| Podman Desktop | ✅ | ✅ | Flatpak (install.sh) |
| Podman TUI | ✅ | ✅ | Nix |
| Lazydocker | ✅ | ✅ | Nix |

---

### 6. CLI UTILITIES (100% Tương Thích)

atuin, yazi, lazygit, btop, eza, bat, fzf, ripgrep, fd, jq - Copy nguyên xi từ Nix.

---

### 7. FONTS

FiraCode Nerd Font - Cài qua Nix (`nerd-fonts.fira-code`)

---

## IMPLEMENTATION PLAN

### PHASE 1: Tạo Profile Ubuntu

**File:** `home/profiles/rnd/default.nix`

**Các bước:**
1. Copy từ `mike/default.nix`
2. Thay đổi thông tin cá nhân (userName, userEmail)
3. Đổi plugin: `macos` → `ubuntu`
4. Disable VSCode config (comment out)
5. Thêm `/snap/bin` vào PATH
6. Điều chỉnh VSCode keybindings (cmd → ctrl)
7. Thêm DOCKER_HOST detection
8. Copy tất cả packages từ Nix

---

### PHASE 2: Đơn Giản Hóa ubuntu.nix

**File:** `home/ubuntu.nix`

**Nội dung:**
```nix
{ config, lib, pkgs, system, inputs, hostname, username, ... }:

{
  imports = [ 
    ./modules/core
    ./modules/shell
    ./modules/dev/git.nix
    ./modules/editors
    ./profiles/${username}
  ];
  
  home.username = username;
  home.homeDirectory = "/home/${username}";
  
  modules = {
    core.enable = true;
    shell.enable = true;
    dev.git.enable = true;
    editors.enable = true;
  };
  
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
```

**Đã xóa:**
- Tất cả activation scripts (dockerSetup, aptPackages, snapPackages)
- Chuyển sang install.sh

---

### PHASE 3: Cập Nhật install.sh

**File:** `install.sh`

**Thêm vào phần Ubuntu:**

1. **Cài đặt build dependencies:**
```bash
sudo apt install -y build-essential curl git zsh flatpak gnome-software-plugin-flatpak gnupg2 \
  autoconf libssl-dev libncurses-dev libreadline-dev zlib1g-dev \
  libbz2-dev libsqlite3-dev libffi-dev liblzma-dev tk-dev
```

2. **Setup Flatpak:**
```bash
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

3. **Cài đặt Docker:**
```bash
if ! command -v docker &>/dev/null; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker $USER
fi
```

4. **Cài đặt Ghostty:**
```bash
if ! command -v ghostty &>/dev/null; then
  wget https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.2.2-0-ppa1/ghostty_1.2.2-0.ppa1_amd64_25.10.deb
  sudo dpkg -i ghostty_1.2.2-0.ppa1_amd64_25.10.deb
  sudo apt-get install -f -y
  rm ghostty_1.2.2-0.ppa1_amd64_25.10.deb
fi
```

5. **Cài đặt Snap packages:**
```bash
for pkg in spotify code; do
  if ! snap list | grep -q "^$pkg "; then
    if [[ "$pkg" == "code" ]]; then
      sudo snap install $pkg --classic
    else
      sudo snap install $pkg
    fi
  fi
done
```

6. **Cài đặt Podman Desktop:**
```bash
if ! flatpak list | grep -q "io.podman_desktop.PodmanDesktop"; then
  flatpak install -y flathub io.podman_desktop.PodmanDesktop
fi
```

---

## CHECKLIST TRIỂN KHAI

### Phase 1: Profile Setup
- [x] Tạo `home/profiles/rnd/default.nix` từ mike
- [x] Thay đổi thông tin cá nhân
- [x] Đổi plugin: macos → ubuntu
- [x] Disable VSCode config (dùng Snap)
- [x] Thêm `/snap/bin` vào PATH
- [x] Điều chỉnh VSCode keybindings (cmd → ctrl)
- [x] Thêm DOCKER_HOST detection
- [x] Copy packages list

### Phase 2: ubuntu.nix
- [x] Đơn giản hóa ubuntu.nix - chỉ giữ cấu hình cơ bản
- [x] Xóa tất cả activation scripts

### Phase 3: install.sh
- [x] Cài đặt build dependencies
- [x] Setup Flatpak repository
- [x] Cài đặt Docker + repository setup
- [x] Cài đặt Snap packages (spotify, ghostty, code)
- [x] Cài đặt Podman Desktop qua Flatpak
- [x] Chạy ASDF planguage.sh
- [x] Copy tmux config

### Phase 4: Testing
- [ ] Chạy install.sh trên Ubuntu
- [ ] Kiểm tra Docker hoạt động
- [ ] Kiểm tra Podman hoạt động
- [ ] Kiểm tra ASDF + languages
- [ ] Kiểm tra VSCode (từ Snap)
- [ ] Kiểm tra Ghostty (từ Snap)
- [ ] Kiểm tra Tmux
- [ ] Kiểm tra ZSH + Starship
- [ ] Kiểm tra tất cả CLI tools

---

## KẾT QUẢ MONG ĐỢI

Sau khi hoàn thành, Ubuntu sẽ có:

✅ ZSH + Oh-My-Zsh + Starship (giống macOS)
✅ Tmux với cấu hình giống hệt
✅ VSCode từ Snap (thay vì Nix)
✅ Git config giống hệt
✅ Neovim giống hệt
✅ Docker Engine + Podman (thay OrbStack)
✅ Podman Desktop qua Flatpak
✅ Kubernetes tools (kubectl, k9s, helm)
✅ CLI utilities (atuin, yazi, lazygit, btop, eza, bat, fzf, etc)
✅ ASDF + Programming languages
✅ Rustup + Cargo
✅ FiraCode Nerd Font
✅ Neofetch
✅ Ghostty terminal từ .deb package
✅ Tất cả aliases và shell config

**Chỉ khác:**
- OrbStack → Docker Engine
- VSCode: Nix → Snap
- Ghostty: Nix → .deb package
- DOCKER_HOST path
- VSCode keybindings (cmd → ctrl)
- Paths (/Users → /home)

---

## PHÂN CHIA TRÁCH NHIỆM

### install.sh (Bootstrap + Package Installation)
**Làm:**
- Cài đặt build dependencies (APT)
- Setup Flatpak repository
- Cài Nix (nếu chưa có)
- Bật flakes
- Chạy Home Manager
- Chạy ASDF script (programming languages)
- Copy tmux config
- Cài đặt Docker + repository setup
- Cài đặt Ghostty (.deb package)
- Cài đặt Snap packages (spotify, code)
- Cài đặt Podman Desktop (Flatpak)
- Add user vào docker group

### ubuntu.nix (Minimal Config)
**Chỉ chứa:**
- Import modules và profile
- Enable modules cơ bản
- Home Manager version

### profile/rnd/default.nix (User Config)
**Chứa:**
- Shell config (ZSH, Starship, aliases)
- Editor config (Neovim, VSCode disabled)
- Git config
- Tmux config
- Nix packages list (fonts, CLI tools, container tools, k8s tools)
- Session variables (PATH với /snap/bin)

---

## LƯU Ý QUAN TRỌNG

1. **Docker Group:** User phải logout/login lại sau khi add vào docker group
2. **Snap Classic:** Chỉ VSCode cần flag --classic
3. **Font:** Dùng `nerd-fonts.fira-code` (cú pháp mới)
4. **ASDF:** Script tự động cài đặt nếu chưa có (hỏi link download)
5. **Rustup:** Script tự động cài đặt và cấu hình shell
6. **Tmux:** File config ở ~/.config/tmux/.tmux.conf
7. **DOCKER_HOST:** Auto-detect trong shell config
8. **Import Profile:** Dùng `./profiles/${username}` (động)
9. **VSCode:** Cài qua Snap (--classic) vì Nix version không chạy được
10. **Ghostty:** Cài qua .deb package (không dùng Snap)
11. **Podman Desktop:** Cài qua Flatpak (không có trên Snap)
12. **PATH:** Phải có `/snap/bin` để chạy Snap apps
12. **Build Dependencies:** Cần cài trước để build Python/Erlang từ source

---

## KIỂM TRA SAU KHI CÀI ĐẶT

```bash
# 1. Logout và login lại để áp dụng docker group và PATH

# 2. Kiểm tra Docker
docker --version
docker ps
groups | grep docker  # Phải có docker group

# 3. Kiểm tra Podman
podman --version

# 4. Kiểm tra Kubernetes tools
kubectl version --client
k9s version
helm version

# 5. Kiểm tra CLI tools
eza --version
bat --version
lazygit --version
btop --version

# 6. Kiểm tra ASDF
asdf list

# 7. Kiểm tra Shell
echo $SHELL  # /usr/bin/zsh hoặc /bin/zsh
starship --version

# 8. Kiểm tra Tmux
tmux -V

# 9. Kiểm tra Snap
snap list  # Phải có: spotify, code

# 10. Kiểm tra VSCode (từ Snap)
which code  # Phải trỏ về /snap/bin/code
code --version

# 11. Kiểm tra Ghostty (từ .deb)
which ghostty  # Phải trỏ về /usr/bin/ghostty
ghostty --version

# 12. Kiểm tra PATH
echo $PATH  # Phải có /snap/bin

# 13. Kiểm tra Flatpak
flatpak list  # Phải có Podman Desktop
```

---

## TROUBLESHOOTING

### VSCode không khởi động
- Kiểm tra: `which code` → phải là `/snap/bin/code`
- Kiểm tra: `echo $PATH` → phải có `/snap/bin`
- Thử: `code --verbose`

### Ghostty không khởi động
- Warnings về GTK theme là bình thường
- Kiểm tra: `which ghostty` → phải là `/snap/bin/ghostty`
- Thử chạy từ terminal: `ghostty`

### Docker không hoạt động
- Kiểm tra: `groups | grep docker`
- Nếu không có: logout và login lại
- Kiểm tra: `docker ps`

### ASDF không tìm thấy
- Script sẽ hỏi link download
- Tải từ: https://github.com/asdf-vm/asdf/releases
- Hoặc cài thủ công theo docs

### Python/Erlang build failed
- Kiểm tra build dependencies đã cài đủ chưa
- Chạy lại: `./asdf-vm/planguage.sh`

---

## THỜI GIAN ƯỚC TÍNH

- Phase 1: 30 phút (tạo profile)
- Phase 2: 5 phút (đơn giản hóa ubuntu.nix)
- Phase 3: 20 phút (cập nhật install.sh)
- Phase 4: 30 phút (testing)

**Tổng:** ~85 phút
