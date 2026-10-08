{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.editors.antigravity;

  # Define Antigravity package (Linux only)
  antigravity = pkgs.stdenv.mkDerivation rec {
    pname = "antigravity";
    inherit (cfg) version;

    src = pkgs.fetchurl {
      inherit (cfg) url sha256;
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];

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
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
      libxshmfence
      pango
      cairo
    ];

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/opt/antigravity
      cp -r * $out/opt/antigravity

      mkdir -p $out/bin
      makeWrapper $out/opt/antigravity/antigravity $out/bin/antigravity \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}
        
      mkdir -p $out/share/applications
      cat > $out/share/applications/antigravity.desktop <<EOF
      [Desktop Entry]
      Name=Antigravity
      Exec=$out/bin/antigravity %F
      Icon=$out/opt/antigravity/resources/app/resources/linux/code.png
      Type=Application
      Categories=Development;
      EOF
    '';
  };
in
{
  options.modules.editors.antigravity = {
    enable = mkEnableOption "Enable Antigravity editor";

    version = mkOption {
      type = types.str;
      default = "1.13.3";
      description = "Version of Antigravity to install (should match versions.json)";
    };

    url = mkOption {
      type = types.str;
      default = "https://antigravity.google/download/linux";
      description = "Download URL for Antigravity Linux package";
    };

    sha256 = mkOption {
      type = types.str;
      default = "";
      description = ''
        SHA256 hash of the Antigravity Linux package.
        Để trống để bỏ qua cài đặt qua Nix.

        LƯU Ý: URL mặc định là trang tải về (HTML), không phải tarball — cần đặt
        `url` trỏ tới file .tar.gz có version cụ thể cùng với hash tương ứng.

        Cập nhật hash khi có version mới:
          nix-prefetch-url --type sha256 https://antigravity.google/download/linux
          nix hash convert --hash-algo sha256 --to sri <hash>
      '';
    };
  };

  # Chỉ cài trên Linux VÀ khi có hash hợp lệ — macOS dùng DMG qua install.sh
  config = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = mkIf (cfg.sha256 != "") [ antigravity ];
    warnings = optional (cfg.sha256 == "") ''
      modules.editors.antigravity: chưa đặt url (tarball có version) + sha256 nên
      Antigravity không được cài qua Nix trên Linux.
    '';
  };
}
