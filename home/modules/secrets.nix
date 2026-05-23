{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.secrets;
in {
  options.modules.secrets = {
    enable = mkEnableOption "Enable secrets management (SOPS + Age)";

    agePublicKeys = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Danh sách Age public keys của team members.
        Dùng để cập nhật .sops.yaml khi thêm người mới.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      sops
      age
    ];

    # Kiểm tra Age key tồn tại — KHÔNG tạo file placeholder (nguy hiểm, ghi đè key thật)
    home.activation.checkAgeKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
      if [ ! -f "$AGE_KEY_FILE" ]; then
        echo ""
        echo "⚠️  Age secret key chưa tồn tại tại: $AGE_KEY_FILE"
        echo "    Tạo keypair mới:"
        echo "      mkdir -p ~/.config/sops/age"
        echo "      age-keygen -o ~/.config/sops/age/keys.txt"
        echo ""
        echo "    Sau đó gửi PUBLIC KEY (dòng # public key: ...) cho team lead"
        echo "    để thêm vào .sops.yaml"
        echo ""
      fi
    '';
  };
}
