{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.secrets;
in {
  options.modules.secrets = {
    enable = mkEnableOption "Enable secrets management";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      sops
      age
    ];

    home.file.".config/sops/age/keys.txt".text = ''
      # Place your Age secret key here
      # AGE-SECRET-KEY-1...
    '';
    
    # Example: Auto-decrypt specific secrets
    # home.file.".config/my-app/secret.json".source = config.lib.file.mkOutOfStoreSymlink 
    #   (pkgs.runCommand "decrypt-secret" {} "sops -d ${./secrets/my-app-secret.json} > $out");
  };
}
