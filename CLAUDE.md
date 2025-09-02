# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a cross-platform dotfiles repository that automatically detects and configures development environments for NixOS, macOS, Ubuntu, and WSL. The project uses Nix flakes for reproducible builds and modular configuration management.

## System Architecture

The repository is organized into several key components:

- **`flake.nix`**: Main entry point defining system configurations and inputs
- **`lib/default.nix`**: System detection utilities and helper functions  
- **`hosts/`**: Platform-specific system configurations (NixOS, Darwin, Ubuntu, WSL)
- **`home/`**: Home Manager configurations organized by platform and user profiles
- **`scripts/`**: Automation scripts for adding users and machines

The build system automatically detects hostname and username from environment variables or system files, with fallback defaults.

## Key Commands

### Installation
```bash
# Automated installation (detects system and sets up everything)
./install.sh

# Manual override with custom hostname/username
HOSTNAME=custom-hostname USERNAME=custom-user ./install.sh
```

### System Management

**NixOS:**
```bash
# Build and switch configuration
sudo nixos-rebuild switch --flake .#hostname

# Generate hardware config for new machine
sudo nixos-generate-config --dir hosts/nixos/machines/hostname
```

**macOS (Darwin):**
```bash
# Build and switch configuration
darwin-rebuild switch --flake .#hostname

# Initial nix-darwin setup
sudo nix run nix-darwin -- switch --flake .#hostname
```

**Ubuntu (Home Manager):**
```bash
# Apply home manager configuration
nix run github:nix-community/home-manager/release-25.05 -- switch --flake .#username@hostname
```

### Development Tools
```bash
# Programming language setup via asdf
chmod +x ./asdf-vm/planguage.sh
bash ./asdf-vm/planguage.sh

# Enter development shell with nix formatting tools
nix develop
```

## Configuration Structure

### Dynamic System Detection
The system uses environment variables and file detection to automatically determine:
- Hostname (from `$HOSTNAME`, `/etc/hostname`, or `$HOST`)
- Username (from `$USER` or `$USERNAME`) 
- Platform (Darwin, NixOS, WSL, Ubuntu)

### User Profiles
User configurations are stored in `home/profiles/username/`. To add a new user:
```bash
./scripts/add-user.sh new-username "Full Name" "email@example.com"
```

### Machine Configurations
Platform-specific machine configs are in `hosts/platform/machines/hostname/`. To add a new machine:
```bash
./scripts/add-machine.sh hostname platform
```

### Module System
Home Manager modules are organized in `home/modules/`:
- **core/**: Essential packages and configurations
- **dev/**: Development tools (Git configuration in `git.nix`)
- **shell/**: Shell configuration and aliases  
- **editors/**: Editor configurations
- **terminal/**: Terminal emulator settings

## Platform-Specific Notes

**macOS**: Integrates Homebrew for packages not available in Nix. Brew packages are defined in machine-specific configs.

**Ubuntu**: Uses Home Manager with optional Snapd integration for additional packages.

**WSL**: Special WSL-optimized NixOS configuration with Windows integration features.

## Git Configuration

Git settings are split between:
- Global configuration in `home/modules/dev/git.nix` (aliases, general settings)
- Personal details in user profiles (`home/profiles/username/default.nix`)

## Important Notes

- All configurations use Nix flakes with the experimental features enabled
- The system supports both static configurations (predefined hostnames) and dynamic detection
- Homebrew on macOS and Snapd on Ubuntu are optional package managers integrated with the Nix setup
- Shell configuration files may be managed by Nix and appear as symlinks