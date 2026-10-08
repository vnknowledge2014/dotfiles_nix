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
  # Module chung (shell, git, editors, terminal, secrets...) được import và bật
  # trong profiles/base — ở đây chỉ khai báo phần riêng của WSL.
  imports = [
    ./profiles/${username}
  ]
  ++ lib.optional hasMachineConfig machineConfigPath;

  # Thông tin cơ bản
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
  };

  modules.shell.zsh.aliases = {
    ll = lib.mkForce "ls -l";
    la = lib.mkForce "ls -la";
    # Clipboard & mở file qua Windows interop (wslu đã bị gỡ khỏi nixpkgs)
    pbcopy = "clip.exe";
    pbpaste = "powershell.exe -NoProfile -Command Get-Clipboard";
    open = "wsl-open";
    explorer = "explorer.exe";
  };

  # PATH của Windows đã được WSL tự nối (wsl.interop.includePath, mặc định true)
  programs.zsh.initContent = lib.mkIf config.programs.zsh.enable ''
    # Mở URL bằng trình duyệt Windows
    export BROWSER="wsl-open"
  '';

  programs.home-manager.enable = true;

  # Repo trên WSL thường được chia sẻ với Windows — giữ LF trong repo
  programs.git.settings.core = {
    autocrlf = "input";
    eol = "lf";
  };

  home.packages = with pkgs; [
    wsl-open
  ];
}
