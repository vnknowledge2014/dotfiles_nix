{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.modules.editors.antigravityIde;

  hasValidHash = cfg.sha256 != "";

  # Antigravity IDE — VS Code-based editor (Linux only)
  # macOS: được cài qua Homebrew Cask "antigravity-ide"
  antigravityIde = pkgs.stdenv.mkDerivation rec {
    pname = "antigravity-ide";
    version = cfg.version;

    src = pkgs.fetchurl {
      url = cfg.url;
      sha256 = cfg.sha256;
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];

    buildInputs = with pkgs; [
      gtk3
      nss
      nspr
      alsa-lib
      cups
      dbus
      expat
      libdrm
      libxkbcommon
      mesa
      at-spi2-atk
      at-spi2-core
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
      xorg.libxshmfence
      pango
      cairo
      # VS Code-based dependencies bổ sung
      libsecret
      xorg.libXtst
    ];

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/opt/antigravity-ide
      cp -r * $out/opt/antigravity-ide

      mkdir -p $out/bin
      makeWrapper $out/opt/antigravity-ide/antigravity-ide $out/bin/antigravity-ide \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}

      mkdir -p $out/share/applications
      cat > $out/share/applications/antigravity-ide.desktop <<EOF
      [Desktop Entry]
      Name=Antigravity IDE
      Comment=AI-powered VS Code-based development environment
      Exec=$out/bin/antigravity-ide %F
      Icon=$out/opt/antigravity-ide/resources/app/resources/linux/code.png
      Type=Application
      Categories=Development;IDE;TextEditor;
      MimeType=text/plain;inode/directory;
      EOF
    '';
  };
in {
  options.modules.editors.antigravityIde = {
    enable = mkEnableOption "Enable Antigravity IDE (VS Code-based)";

    version = mkOption {
      type = types.str;
      default = "latest";
      description = "Phiên bản Antigravity IDE cần cài đặt";
    };

    url = mkOption {
      type = types.str;
      default = "https://antigravity.google/download/linux/ide";
      description = "URL tải Antigravity IDE cho Linux";
    };

    sha256 = mkOption {
      type = types.str;
      default = "";
      description = ''
        SHA256 hash của gói Antigravity IDE Linux.
        Để trống để bỏ qua cài đặt qua Nix (macOS luôn dùng Homebrew Cask).

        Cập nhật hash khi có version mới:
          nix-prefetch-url --type sha256 https://antigravity.google/download/linux/ide
          nix hash convert --hash-algo sha256 --to sri <hash>
      '';
    };
  };

  # Chỉ cài trên Linux VÀ khi có SHA256 hợp lệ — macOS dùng Homebrew Cask
  config = mkIf (cfg.enable && pkgs.stdenv.isLinux && hasValidHash) {
    home.packages = [ antigravityIde ];
  };
}
