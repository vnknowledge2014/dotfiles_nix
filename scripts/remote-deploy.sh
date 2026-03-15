#!/bin/bash

# Remote Deploy Script
# Deploy dotfiles to a remote machine via SSH

set -e

# Usage: ./remote-deploy.sh user@host [preset]
TARGET=$1
PRESET=${2:-all}

if [ -z "$TARGET" ]; then
    echo "Usage: $0 user@host [preset]"
    echo "Example: $0 mike@192.168.1.100 web-developer"
    exit 1
fi

echo "Deploying to $TARGET with preset '$PRESET'..."

# 1. Install git if missing
echo "Checking git on remote..."
ssh -t "$TARGET" "command -v git >/dev/null || (sudo apt update && sudo apt install -y git) || (sudo pacman -S --noconfirm git) || (sudo dnf install -y git)"

# 2. Clone repo
echo "Cloning dotfiles..."
ssh -t "$TARGET" "
    if [ ! -d ~/dotfiles ]; then
        git clone https://github.com/vnknowledge2014/dotfiles_nix.git ~/dotfiles
    else
        cd ~/dotfiles && git pull
    fi
"

# 3. Run install
echo "Running install.sh..."
ssh -t "$TARGET" "cd ~/dotfiles && ./install.sh --preset $PRESET"

echo "Deployment complete!"
