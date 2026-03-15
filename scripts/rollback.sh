#!/bin/bash

# Rollback Script
# Khôi phục trạng thái hệ thống về thế hệ trước (Nix generation)

set -e

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                  SYSTEM ROLLBACK                          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Detect System
if [[ "$(uname)" == "Darwin" ]]; then
    SYSTEM="darwin"
elif grep -q "NixOS" /etc/os-release 2>/dev/null; then
    SYSTEM="nixos"
else
    SYSTEM="home-manager" # Ubuntu/Other Linux using Home Manager standalone
fi

rollback_darwin() {
    echo -e "${BLUE}Rolling back macOS (nix-darwin)...${NC}"
    # Darwin generations are usually in /nix/var/nix/profiles/system-profiles/
    # But nix-darwin switch manages the profile directly.
    # The standard way to rollback nix-darwin is usually finding the previous generation in the profile
    # and activating it.
    
    PROFILE="/nix/var/nix/profiles/system"
    if [ ! -d "$PROFILE" ]; then
         # Fallback to current user profile if system profile not found (common in some setups)
         PROFILE="$HOME/.nix-profile" 
    fi

    echo "Current generation:"
    ls -l $PROFILE | grep " -> " || echo "Unknown"
    
    echo "Rolling back..."
    if sudo darwin-rebuild --rollback; then
        echo -e "${GREEN}✓ Rollback successful${NC}"
    else
        echo -e "${RED}✗ Rollback failed${NC}"
        echo "Try listing generations with: home-manager generations"
    fi
}

rollback_nixos() {
    echo -e "${BLUE}Rolling back NixOS...${NC}"
    if sudo nixos-rebuild switch --rollback; then
        echo -e "${GREEN}✓ Rollback successful${NC}"
    else
        echo -e "${RED}✗ Rollback failed${NC}"
    fi
}

rollback_home_manager() {
    echo -e "${BLUE}Rolling back Home Manager...${NC}"
    # Home Manager doesn't have a direct "--rollback" flag in the CLI always exposed cleanly like nixos-rebuild
    # But we can find the previous generation and activate it.
    
    # Simple approach: List generations and ask user? Or just naive rollback?
    # Let's try the generation activator approach
    
    GEN_PATH=$(ls -d $HOME/.local/state/nix/profiles/home-manager-*-link 2>/dev/null | sort -V | tail -n 2 | head -n 1)
    
    if [ -z "$GEN_PATH" ]; then
        # Try legacy path
        GEN_PATH=$(ls -d $HOME/.nix-profile/home-manager-*-link 2>/dev/null | sort -V | tail -n 2 | head -n 1)
    fi

    if [ -n "$GEN_PATH" ]; then
        echo "Switching to previous generation: $GEN_PATH"
        "$GEN_PATH/activate"
        echo -e "${GREEN}✓ Rollback successful${NC}"
    else
        echo -e "${RED}✗ Could not find previous generation to rollback to.${NC}"
        echo "You can list generations manually: home-manager generations"
    fi
}

case $SYSTEM in
    darwin)
        rollback_darwin
        ;;
    nixos)
        rollback_nixos
        ;;
    home-manager)
        rollback_home_manager
        ;;
esac
