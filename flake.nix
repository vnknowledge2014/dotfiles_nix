{
  description = "Dotfiles đa nền tảng cho NixOS, macOS, Ubuntu và WSL — Team-ready";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/release-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    # Hardware NixOS
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    
    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # macOS
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # WSL
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-hardware, 
              home-manager, darwin, nixos-wsl, ... }@inputs:
    let
      # ═══════════════════════════════════════════════════════════
      # PURE EVALUATION — Không dùng builtins.getEnv hay readFile
      # Mọi hostname/username đều được hardcode bên dưới
      # ═══════════════════════════════════════════════════════════
      
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
      
      # ═══════════════════════════════════════════════════════════
      # BUILDER FUNCTIONS — Tạo cấu hình cho từng nền tảng
      # ═══════════════════════════════════════════════════════════
      
      # NixOS (bao gồm cả WSL)
      mkNixOS = { hostname, username, system ? "x86_64-linux", isWSL ? false }: 
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { 
            inherit inputs system hostname username;
            host = hostname;
            user = username;
          };
          modules = [
            ./hosts/common
            # NixOS-specific: lix, nix.gc, ZFS, locale (bỏ qua cho WSL)
            (if isWSL then nixos-wsl.nixosModules.default else ./hosts/nixos/common.nix)
            (if isWSL 
              then ./hosts/wsl
              else ./hosts/nixos/machines/${hostname})
            home-manager.nixosModules.home-manager
            {
              networking.hostName = hostname;
              nixpkgs.config.allowUnfree = true;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs system hostname username; };
                users.${username} = import (
                  if isWSL then ./home/wsl.nix else ./home/nixos.nix
                );
              };
            }
          ];
        };
      
      # macOS (Darwin)
      mkDarwin = { hostname, username, system ? "aarch64-darwin" }: 
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { 
            inherit inputs system hostname username;
            host = hostname;
            user = username;
          };
          modules = [
            ./hosts/common
            ./hosts/darwin
            ./hosts/darwin/machines/${hostname}
            home-manager.darwinModules.home-manager
            {
              nixpkgs.config.allowUnfree = true;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit inputs system hostname username; };
                users.${username} = import ./home/darwin.nix;
              };
            }
          ];
        };
      
      # Ubuntu (Home Manager standalone)
      mkUbuntu = { hostname, username, system ? "x86_64-linux" }: 
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgsFor.${system};
          extraSpecialArgs = { 
            inherit inputs system hostname username;
            host = hostname;
            user = username;
          };
          modules = [
            ./home/ubuntu.nix
          ];
        };
    in
    {
      # ═══════════════════════════════════════════════════════════
      # CONFIGURATIONS — Hardcoded, mỗi máy 1 entry
      # ═══════════════════════════════════════════════════════════
      # Thêm máy mới: copy 1 entry, đổi hostname/username/system
      # Rồi tạo profile + machine config bằng:
      #   ./scripts/add-user.sh <username>
      #   ./scripts/add-machine.sh <hostname> <os>
      # ═══════════════════════════════════════════════════════════
      
      nixosConfigurations = {
        # WSL instance
        wsl = mkNixOS {
          hostname = "wsl";
          username = "rnd";
          system = "x86_64-linux";
          isWSL = true;
        };
        
        # Thêm máy NixOS: 
        # my-server = mkNixOS { hostname = "my-server"; username = "admin"; };
      };
      
      darwinConfigurations = {
        # MacBook chính
        macbook = mkDarwin {
          hostname = "macbook";
          username = "mike";
          system = "x86_64-darwin";
        };
        
        # Thêm máy macOS:
        # macbook-pro = mkDarwin { hostname = "macbook-pro"; username = "alice"; system = "aarch64-darwin"; };
      };
      
      homeConfigurations = {
        # Ubuntu PC
        "rnd@ubuntu" = mkUbuntu {
          hostname = "ubuntu";
          username = "rnd";
        };
        
        # Thêm Ubuntu:
        # "bob@dev-machine" = mkUbuntu { hostname = "dev-machine"; username = "bob"; };
      };
      
      # ═══════════════════════════════════════════════════════════
      # FORMATTER — `nix fmt` sẽ dùng nixfmt-rfc-style (RFC 166)
      # ═══════════════════════════════════════════════════════════
      formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt-rfc-style);
      
      # ═══════════════════════════════════════════════════════════
      # DEV SHELL — `nix develop` cho contributors
      # ═══════════════════════════════════════════════════════════
      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system}; in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nixfmt-rfc-style  # Formatter (RFC 166)
              nil               # Nix LSP
              statix            # Nix linter
              deadnix           # Phát hiện dead code
            ];
            shellHook = ''
              echo "🔧 Dotfiles Dev Shell"
              echo "  nix fmt        — Format tất cả file .nix"
              echo "  statix check . — Lint Nix code"
              echo "  deadnix .      — Tìm dead code"
            '';
          };
        }
      );
    };
}