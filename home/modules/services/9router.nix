{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.modules.services."9router";
  
  # Wrapper script to run 9router via npx
  router-script = pkgs.writeShellScriptBin "9router" ''
    # Ensure nodejs and npm are available in PATH
    export PATH="${pkgs.nodejs}/bin:$PATH"
    
    # Run 9router (npx will auto-download if not present)
    exec npx -y 9router@0.5.45 "$@"
  '';
in {
  options.modules.services."9router" = {
    enable = mkEnableOption "9router AI proxy service";
  };

  config = mkIf cfg.enable {
    # Cài đặt lệnh '9router' khả dụng trên terminal toàn cục
    home.packages = [ router-script ];
  };
}
