#!/bin/bash
# Setup pre-commit hooks and GitGuardian
# Usage: ./setup-pre-commit.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEARN_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setting up Pre-commit & GitGuardian${NC}"
echo -e "${GREEN}========================================${NC}\n"

cd "$LEARN_DIR"

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo -e "${YELLOW}pre-commit not found. Installing...${NC}"

    # Try pip3 first, then pip
    if command -v pip3 &> /dev/null; then
        pip3 install pre-commit
    elif command -v pip &> /dev/null; then
        pip install pre-commit
    else
        echo -e "${RED}Error: pip/pip3 not found. Please install Python and pip first.${NC}"
        echo -e "${YELLOW}Install with:${NC}"
        echo "  sudo apt-get install python3-pip  # Ubuntu/Debian"
        echo "  brew install python3              # macOS"
        exit 1
    fi
fi

echo -e "${GREEN}✓ pre-commit installed${NC}\n"

# Check if GitGuardian CLI is installed
if ! command -v ggshield &> /dev/null; then
    echo -e "${YELLOW}GitGuardian CLI (ggshield) not found. Installing...${NC}"

    if command -v pip3 &> /dev/null; then
        pip3 install ggshield
    elif command -v pip &> /dev/null; then
        pip install ggshield
    else
        echo -e "${RED}Error: pip/pip3 not found.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ GitGuardian CLI installed${NC}\n"

# Install pre-commit hooks
echo -e "${BLUE}Installing pre-commit hooks...${NC}"
pre-commit install
echo -e "${GREEN}✓ Pre-commit hooks installed${NC}\n"

# Run pre-commit on all files (first time)
echo -e "${BLUE}Running pre-commit on all files (first time setup)...${NC}"
echo -e "${YELLOW}This may take a few minutes...${NC}\n"

pre-commit run --all-files || {
    echo -e "${YELLOW}⚠️  Some checks failed. This is normal on first run.${NC}"
    echo -e "${YELLOW}Review the output above and fix any issues.${NC}\n"
}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Next Steps:${NC}\n"

echo -e "1. ${YELLOW}Configure GitGuardian API key (optional but recommended):${NC}"
echo -e "   ${CYAN}ggshield auth login${NC}"
echo -e "   Or set environment variable: ${CYAN}export GITGUARDIAN_API_KEY=your-key${NC}\n"

echo -e "2. ${YELLOW}Test pre-commit hooks:${NC}"
echo -e "   ${CYAN}pre-commit run --all-files${NC}\n"

echo -e "3. ${YELLOW}Hooks will run automatically on:${NC}"
echo -e "   - ${GREEN}git commit${NC} (before commit)"
echo -e "   - ${GREEN}git push${NC} (before push, if configured)"
echo -e "   - ${GREEN}Manual: pre-commit run${NC}\n"

echo -e "${BLUE}Available Commands:${NC}"
echo -e "  ${CYAN}pre-commit run${NC}              - Run hooks on staged files"
echo -e "  ${CYAN}pre-commit run --all-files${NC}   - Run hooks on all files"
echo -e "  ${CYAN}pre-commit autoupdate${NC}       - Update hook versions"
echo -e "  ${CYAN}ggshield scan${NC}                - Manual GitGuardian scan"
echo -e "  ${CYAN}ggshield auth status${NC}        - Check GitGuardian auth\n"

echo -e "${GREEN}✓ Pre-commit and GitGuardian are ready!${NC}\n"
