{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.modules.editors.antigravity;
  
  hasValidHash = cfg.sha256 != "";

  # Define Antigravity package (Linux only)
  antigravity = pkgs.stdenv.mkDerivation rec {
    pname = "antigravity";
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
in {
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
      default = "sha256-jIO5wWE/U1PvTEXrMrzpafbhs12rEj0hvbB1Oq7Rg7s=";
      description = ''
        SHA256 hash of the Antigravity Linux package.
        Để trống để bỏ qua cài đặt qua Nix.

        Cập nhật hash khi có version mới:
          nix-prefetch-url --type sha256 https://antigravity.google/download/linux
          nix hash convert --hash-algo sha256 --to sri <hash>
      '';
    };
  };

  # Chỉ cài trên Linux VÀ khi có hash hợp lệ — macOS dùng DMG qua install.sh
  # Khi sha256 rỗng → bỏ qua, build không fail
  config = mkIf (cfg.enable && pkgs.stdenv.isLinux && hasValidHash) {
    home.packages = [ antigravity ];
  };
}
