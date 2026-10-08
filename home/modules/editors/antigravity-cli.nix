{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.editors.antigravityCli;

  # Antigravity CLI — Terminal-first AI agent interface
  # macOS: được cài qua Homebrew Cask "antigravity-cli"
  # Linux: fetch binary từ install script chính thức và đóng gói vào Nix store
  antigravityCli = pkgs.stdenv.mkDerivation rec {
    pname = "antigravity-cli";
    inherit (cfg) version;

    # Sử dụng fetchurl để lấy binary pre-built từ URL chính thức
    src = pkgs.fetchurl {
      inherit (cfg) url sha256;
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];

    buildInputs = with pkgs; [
      # Các runtime dependency tối thiểu cho CLI binary (Node.js-based)
      stdenv.cc.cc.lib
      glibc
    ];

    # Binary archive: extract và install
    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/bin $out/lib/antigravity-cli

      # Nếu là tarball chứa thư mục bin/
      if [ -f antigravity-cli ]; then
        install -Dm755 antigravity-cli $out/bin/antigravity-cli
      elif [ -d bin ]; then
        cp -r bin/. $out/bin/
        cp -r lib/. $out/lib/antigravity-cli/ 2>/dev/null || true
      fi

      # Wrap để đảm bảo LD_LIBRARY_PATH đúng trên NixOS
      if [ -f $out/bin/antigravity-cli ]; then
        wrapProgram $out/bin/antigravity-cli \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}
      fi
    '';
  };

  # Fallback: Cài bằng activation script (dùng install.sh từ trang chủ)
  # Áp dụng khi không có sha256 hoặc muốn dùng phiên bản mới nhất
  # PATH lúc activation của Home Manager không có ~/.local/bin, ~/.antigravity/bin...
  # nên kiểm tra trực tiếp các vị trí install script hay đặt binary.
  cliInstallScript = ''
    found=""
    for bin in antigravity-cli agy; do
      for dir in "$HOME/.local/bin" "$HOME/.antigravity/bin" "$HOME/bin" /usr/local/bin; do
        [ -x "$dir/$bin" ] && found="$dir/$bin"
      done
    done
    if [ -z "$found" ]; then
      echo "[antigravity-cli] Đang cài đặt bằng install script chính thức..."
      script="$(${pkgs.coreutils}/bin/mktemp)"
      if ${pkgs.curl}/bin/curl -fsSL https://antigravity.google/cli/install.sh -o "$script"; then
        PATH="${
          lib.makeBinPath [
            pkgs.curl
            pkgs.coreutils
            pkgs.gnutar
            pkgs.gzip
            pkgs.unzip
          ]
        }:$PATH" \
          $DRY_RUN_CMD ${pkgs.bash}/bin/bash "$script" || echo "[antigravity-cli] Cài đặt thất bại — bỏ qua"
      else
        echo "[antigravity-cli] Không tải được install script (offline?) — bỏ qua"
      fi
      rm -f "$script"
    fi
  '';
in
{
  options.modules.editors.antigravityCli = {
    enable = mkEnableOption "Enable Antigravity CLI";

    version = mkOption {
      type = types.str;
      default = "latest";
      description = "Phiên bản Antigravity CLI cần cài đặt";
    };

    url = mkOption {
      type = types.str;
      default = "https://antigravity.google/cli/download/linux";
      description = "URL tải binary Antigravity CLI cho Linux (nếu có)";
    };

    sha256 = mkOption {
      type = types.str;
      default = "";
      description = ''
        SHA256 hash của binary Antigravity CLI.
        - Để trống → dùng activation script (install.sh chính thức) — KHUYẾN NGHỊ cho Linux
        - Điền hash → build từ pre-built binary qua Nix derivation (reproducible)

        Cập nhật hash khi có version mới:
          nix-prefetch-url --type sha256 https://antigravity.google/cli/download/linux
          nix hash convert --hash-algo sha256 --to sri <hash>
      '';
    };

    useInstallScript = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Nếu true và sha256 để trống: dùng install script chính thức của Antigravity CLI.
        Đây là phương pháp an toàn nhất để luôn nhận được phiên bản mới nhất.
      '';
    };
  };

  config = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    # Mode 1: Reproducible Nix derivation (khi có sha256)
    home.packages = mkIf (cfg.sha256 != "") [ antigravityCli ];

    # Mode 2: Install script chính thức (mặc định — luôn có bản mới nhất)
    home.activation.installAntigravityCli = mkIf (cfg.sha256 == "" && cfg.useInstallScript) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${cliInstallScript}
      ''
    );
  };
}
