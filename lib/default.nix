{ nixpkgs, ... }:

let
  inherit (nixpkgs) lib;

  # Phát hiện WSL
  isWSL = 
    if builtins.pathExists "/proc/sys/kernel/osrelease" then
      lib.hasInfix "microsoft" (builtins.readFile "/proc/sys/kernel/osrelease")
    else
      false;

  # Phát hiện Ubuntu
  isUbuntu =
    if builtins.pathExists "/etc/os-release" then
      lib.hasInfix "Ubuntu" (builtins.readFile "/etc/os-release")
    else
      false;
in
{
  # Phát hiện hostname
  getHostName = let
    envHostname = builtins.getEnv "HOSTNAME";
    fallback = "default-host";
  in
    if envHostname != "" then envHostname
    else if builtins.pathExists "/etc/hostname" then
      builtins.readFile "/etc/hostname"
    else if builtins.getEnv "HOST" != "" then
      builtins.getEnv "HOST"
    else
      fallback;

  # Phát hiện username
  getUserName = let
    envUser = builtins.getEnv "USER";
    envUsername = builtins.getEnv "USERNAME";
    fallback = "default-user";
  in
    if envUser != "" then envUser
    else if envUsername != "" then envUsername
    else
      fallback;

  # Phát hiện hệ thống
  detectSystem = 
    let
      isMac = builtins.match ".*darwin.*" (builtins.currentSystem or "");
      isLinux = builtins.match ".*linux.*" (builtins.currentSystem or "");
    in
      if isMac != null then "darwin"
      else if isLinux != null then
        if builtins.pathExists "/etc/NIXOS" then
          if isWSL then "nixos-wsl" else "nixos"
        else if isUbuntu then "ubuntu"
        else "unknown-linux"
      else "unknown";

  # Xuất biến
  inherit isWSL isUbuntu;
}