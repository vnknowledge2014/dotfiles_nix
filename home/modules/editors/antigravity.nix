{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.modules.editors.antigravity;
  
  # Define Antigravity package (Linux only)
  antigravity = pkgs.stdenv.mkDerivation rec {
    pname = "antigravity";
    version = "1.13.3"; # Should match versions.json

    src = pkgs.fetchurl {
      url = "https://antigravity.google/download/linux";
      # Lần build đầu tiên sẽ fail với hash mismatch.
      # Nix sẽ in ra hash đúng — copy hash đó vào đây để thay thế fakeHash.
      # Ví dụ: sha256 = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
      sha256 = lib.fakeHash;
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
  };

  # Chỉ cài trên Linux — macOS dùng DMG qua install.sh
  config = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ antigravity ];
  };
}
