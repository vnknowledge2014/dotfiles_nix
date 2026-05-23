{ nixpkgs, ... }:

# Thư viện tiện ích — CHỈ CHỨA HÀM PURE
# Không dùng builtins.getEnv, builtins.readFile, hay bất kỳ I/O nào
# Tất cả hostname/username phải được hardcode trong flake.nix

{
  # Phát hiện nhóm hệ điều hành từ builtins.currentSystem (pure)
  detectPlatform = system:
    let
      inherit (nixpkgs) lib;
      isDarwin = lib.hasSuffix "-darwin" system;
      isLinux = lib.hasSuffix "-linux" system;
      isAarch64 = lib.hasPrefix "aarch64-" system;
    in {
      inherit isDarwin isLinux isAarch64 system;
      # Trả về tên ngắn gọn cho conditional logic
      os = if isDarwin then "darwin" else if isLinux then "linux" else "unknown";
      arch = if isAarch64 then "aarch64" else "x86_64";
    };
}