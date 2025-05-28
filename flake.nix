{
  description = "Dotfiles đa nền tảng cho NixOS, macOS, Ubuntu và WSL";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    # Hardware NixOS
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    
    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # macOS
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # WSL
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Apps
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-hardware, 
              home-manager, darwin, nixos-wsl, zen-browser, ... }@inputs:
    let
      # Import thư viện tiện ích
      lib = import ./lib { inherit nixpkgs; };
      
      # Phát hiện hệ thống
      getHostName = lib.getHostName;
      getUserName = lib.getUserName;
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      
      # Helper tạo attrset cho các hệ thống được hỗ trợ
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      # Khởi tạo nixpkgs với allowUnfree
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
      
      # Hàm tạo cấu hình NixOS
      mkNixOS = { hostname ? getHostName, username ? getUserName, 
                  system ? "x86_64-linux", isWSL ? false }: 
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { 
            inherit inputs system hostname username;
            host = hostname;
            user = username;
          };
          modules = [
            ./hosts/common
            (if isWSL 
              then ./hosts/wsl
              else ./hosts/nixos/machines/${hostname})
            home-manager.nixosModules.home-manager
            {
              networking.hostName = hostname;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home/nixos.nix;
              home-manager.extraSpecialArgs = { inherit inputs system hostname username; };
              nixpkgs.config.allowUnfree = true;
            }
          ];
        };
      
      # Hàm tạo cấu hình macOS (Darwin)
      mkDarwin = { hostname ? getHostName, username ? getUserName, 
                    system ? "x86_64-darwin" }: 
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
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home/darwin.nix;
              home-manager.extraSpecialArgs = { inherit inputs system hostname username; };
              nixpkgs.config.allowUnfree = true;
            }
          ];
        };
      
      # Hàm tạo cấu hình Home Manager cho Ubuntu
      mkUbuntu = { hostname ? getHostName, username ? getUserName, 
                   system ? "x86_64-linux" }: 
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
      # Cấu hình NixOS
      nixosConfigurations = {
        # Cấu hình Legion
        legion = mkNixOS {
          hostname = "legion";
          username = "rnd";
          system = "x86_64-linux";
        };
        
        # Cấu hình WSL
        wsl = mkNixOS {
          hostname = "wsl";
          username = "rnd";
          system = "x86_64-linux";
          isWSL = true;
        };
        
        # Cấu hình động theo hostname
        ${getHostName} = mkNixOS {
          hostname = getHostName;
          username = getUserName;
        };
      };
      
      # Cấu hình macOS (Darwin)
      darwinConfigurations = {
        # Cấu hình macbook
        macbook = mkDarwin {
          hostname = "macbook";
          username = "mike";
          system = "x86_64-darwin";
        };
        
        # Cấu hình động theo hostname
        ${getHostName} = mkDarwin {
          hostname = getHostName;
          username = getUserName;
        };
      };
      
      # Cấu hình Home Manager cho Ubuntu
      homeConfigurations = {
        # Cấu hình Ubuntu
        "${getUserName}@${getHostName}" = mkUbuntu {
          hostname = getHostName;
          username = getUserName;
        };
        
        # Cấu hình cố định
        "rnd@ubuntu" = mkUbuntu {
          hostname = "ubuntu";
          username = "rnd";
        };
      };
      
      # Tùy chọn khác (shell phát triển, v.v.)
      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system}; in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nixpkgs-fmt
              nil
            ];
          };
        }
      );
    };
}