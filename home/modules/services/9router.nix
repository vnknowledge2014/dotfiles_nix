{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.modules.services."9router";
  
  # Wrapper script to run 9router via npx
  router-script = pkgs.writeShellScriptBin "9router-start" ''
    # Ensure nodejs and npm are available in PATH
    export PATH="${pkgs.nodejs}/bin:$PATH"
    
    # Run 9router (npx will auto-download if not present)
    echo "Starting 9router..."
    exec npx -y 9router@0.5.45 --no-browser --tray
  '';
in {
  options.modules.services."9router" = {
    enable = mkEnableOption "9router AI proxy service";
  };

  config = mkIf cfg.enable {
    # Provide the wrapper script globally just in case the user wants to run it manually
    home.packages = [ router-script ];

    # macOS daemon via launchd
    launchd.agents."9router" = mkIf pkgs.stdenv.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [ "${router-script}/bin/9router-start" ];
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/9router.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/9router.log";
      };
    };

    # Linux daemon via systemd user services
    systemd.user.services."9router" = mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "9Router AI Proxy Server";
        After = [ "network.target" ];
      };
      Service = {
        ExecStart = "${router-script}/bin/9router-start";
        Restart = "always";
        RestartSec = "10";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
