#!/bin/bash

# Dotfiles Doctor (formerly verify.sh)
# Kiểm tra sức khỏe hệ thống và đề xuất sửa lỗi

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0
SUGGESTIONS=()

# Hàm kiểm tra
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
    if [ -n "$2" ]; then
        SUGGESTIONS+=("$2")
    fi
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
    if [ -n "$2" ]; then
        SUGGESTIONS+=("$2")
    fi
}

check_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Header
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              DOTFILES DOCTOR                              ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# 1. Kiểm tra Nix
echo "=== Nix & System ==="
if command -v nix &>/dev/null; then
    NIX_VERSION=$(nix --version 2>/dev/null | head -1)
    check_pass "Nix installed ($NIX_VERSION)"
else
    check_fail "Nix not installed" "Install Nix: curl -L https://nixos.org/nix/install | sh"
fi

# 2. Kiểm tra Home Manager
if command -v home-manager &>/dev/null; then
    check_pass "Home Manager installed"
else
    check_warn "Home Manager CLI not available" "Enable 'programs.home-manager.enable = true;' in configuration"
fi

# 3. Kiểm tra Shell
echo ""
echo "=== Shell ==="
CURRENT_SHELL=$(basename "$SHELL")
if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    check_pass "ZSH is default shell"
else
    check_warn "Default shell is $CURRENT_SHELL" "Change shell: chsh -s $(which zsh)"
fi

if command -v starship &>/dev/null; then
    check_pass "Starship installed"
else
    check_warn "Starship not found" "Check 'programs.starship.enable = true;'"
fi

# 4. Kiểm tra Git
echo ""
echo "=== Git ==="
if command -v git &>/dev/null; then
    GIT_USER=$(git config --global user.name 2>/dev/null)
    GIT_EMAIL=$(git config --global user.email 2>/dev/null)
    if [[ -n "$GIT_USER" && -n "$GIT_EMAIL" ]]; then
        check_pass "Git configured ($GIT_USER)"
    else
        check_warn "Git identity missing" "Run: git config --global user.name 'Your Name' && git config --global user.email 'you@example.com'"
    fi
else
    check_fail "Git not installed" "Add 'git' to system packages"
fi

# 5. Kiểm tra Secrets
echo ""
echo "=== Secrets ==="
if command -v sops &>/dev/null; then
    check_pass "SOPS installed"
else
    check_warn "SOPS not installed" "Add 'sops' to environment"
fi
if [[ -f "$HOME/.config/sops/age/keys.txt" ]]; then
    check_pass "Age keys found"
else
    check_warn "Age keys missing" "Generate key: age-keygen -o ~/.config/sops/age/keys.txt"
fi

# 6. Kiểm tra asdf
echo ""
echo "=== Languages (asdf) ==="
if command -v asdf &>/dev/null; then
    check_pass "asdf installed"
    # Helper to check language
    check_lang() {
        if asdf list $1 &>/dev/null; then return 0; else return 1; fi
    }
    
    # Check some common langs
    if check_lang "nodejs"; then check_pass "Node.js installed"; else check_info "Node.js not installed"; fi
    if check_lang "python"; then check_pass "Python installed"; else check_info "Python not installed"; fi
    if check_lang "rust"; then check_pass "Rust (asdf) installed"; else check_info "Rust (asdf) not installed"; fi
else
    check_warn "asdf not found" "Run: ./install.sh --preset <your-preset>"
fi

# 7. Kiểm tra Rustup
echo ""
echo "=== Rustup ==="
if command -v rustup &>/dev/null; then
    check_pass "Rustup installed"
    if rustup component list --installed 2>/dev/null | grep -q "rust-analyzer"; then
        check_pass "rust-analyzer ready"
    else
        check_warn "rust-analyzer missing" "Run: rustup component add rust-analyzer"
    fi
else
    check_info "Rustup not installed"
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}STATUS: HEALTHY${NC}"
else
    echo -e "${RED}STATUS: UNHEALTHY${NC}"
fi

echo "  ✓ Passed:   $PASSED"
echo "  ✗ Failed:   $FAILED"
echo "  ⚠ Warnings: $WARNINGS"

if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
    echo ""
    echo "=== Doctor's Suggestions ==="
    for suggest in "${SUGGESTIONS[@]}"; do
        echo -e "${YELLOW}👉 $suggest${NC}"
    done
fi
echo ""

exit $FAILED
