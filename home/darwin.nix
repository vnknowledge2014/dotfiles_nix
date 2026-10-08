{
  config,
  lib,
  pkgs,
  hostname,
  username,
  ...
}:

let
  # Check if machine-specific config exists
  machineConfigPath = ./profiles/${username}/machines/${hostname}.nix;
  hasMachineConfig = builtins.pathExists machineConfigPath;
in
{
  # Import các module cơ bản và machine-specific config nếu tồn tại
  imports = [
    ./modules/core
    ./modules/shell
    ./modules/dev/git.nix
    ./modules/editors
    ./modules/terminal
    ./profiles/${username}
  ]
  ++ lib.optional hasMachineConfig machineConfigPath;

  # Thông tin cơ bản
  home = {
    inherit username;
    homeDirectory = lib.mkForce "/Users/${username}";
    stateVersion = "26.05";
  };

  # Kích hoạt các module cơ bản
  modules = {
    core = {
      enable = true;
      packages = with pkgs; [

      ];
    };

    dev.git.enable = true;
    editors.enable = true;
    terminal.enable = true;

    shell.zsh.ohmyzsh.plugins = [ "macos" ];
  };

  # Các gói cơ bản cho macOS
  home.packages = with pkgs; [
    # CLI tools
    coreutils
    gnugrep
    findutils
    gnused
    gawk
  ];

  # Darwin-specific activation
  home.activation = {
    fixLaunchAgentsPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/Library/LaunchAgents"
      $DRY_RUN_CMD chmod $VERBOSE_ARG 755 "$HOME/Library/LaunchAgents"
    '';
  };

  # Integracja z Homebrew
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkIf config.programs.zsh.enable ''
      # Homebrew integration
      if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi

      # OpenZFS tools — prioritize 2.3.1 userland matching the loaded kext
      # Prevents version mismatch with /usr/local/sbin/zpool (1.9.4)
      if [ -d /usr/local/zfs/bin ]; then
        export PATH="/usr/local/zfs/bin:/usr/local/zfs/sbin:$PATH"
      fi
    '')

    # Language runtimes are asdf's job on this machine, not Homebrew's.
    #
    # base/default.nix already puts the asdf shims on PATH, but `brew shellenv`
    # above runs afterwards and prepends /usr/local/bin — so every tool Homebrew
    # also ships (node, python, ruby, go…) shadowed the version named in
    # .tool-versions. That is how a Homebrew `node`, pulled in only as another
    # formula's dependency, came to outrank the asdf runtime: when Homebrew's
    # copy broke, every project broke with it while asdf's own node was fine.
    #
    # mkAfter runs last, so re-prepending here keeps asdf ahead of Homebrew no
    # matter how the block above is ordered.
    (lib.mkAfter ''
      if [ -d "''${ASDF_DATA_DIR:-$HOME/.asdf}/shims" ]; then
        export PATH="''${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
      fi
    '')
  ];

  # Phiên bản Home Manager
  programs.home-manager.enable = true;
}
