{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.editors;
in {
  options.modules.editors = {
    enable = mkEnableOption "Enable editors configuration";
    
    neovim = {
      enable = mkEnableOption "Enable Neovim configuration";
    };
    
    vscode = {
      enable = mkEnableOption "Enable VSCode configuration";
    };
  };

  config = mkIf cfg.enable {
    # Neovim configuration
    programs.neovim = mkIf cfg.neovim.enable {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
    
    # VSCode configuration
    programs.vscode = mkIf cfg.vscode.enable {
      enable = true;
      package = pkgs.vscode;
    };
  };
}