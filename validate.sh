#!/usr/bin/env bash
# Validation script for kiosk fleet configuration

set -e

echo "🔍 Validating kiosk-fleet configuration..."
echo ""

# Check if nix is available
if ! command -v nix &> /dev/null; then
    echo "❌ Nix is not installed. This script must be run on a NixOS system or with Nix installed."
    exit 1
fi

echo "✅ Nix found"

# Check if flake.nix exists
if [ ! -f "flake.nix" ]; then
    echo "❌ flake.nix not found. Run this script from the repository root."
    exit 1
fi

echo "✅ flake.nix found"

# Check flake syntax
echo ""
echo "📋 Checking flake syntax..."
if nix flake check --no-build 2>&1 | grep -q "error:"; then
    echo "❌ Flake syntax errors detected"
    nix flake check --no-build
    exit 1
else
    echo "✅ Flake syntax is valid"
fi

# Show available configurations
echo ""
echo "📦 Available configurations:"
nix flake show 2>/dev/null || echo "⚠️  Could not show flake outputs"

# Check if GitHub URL is still template
echo ""
echo "🔗 Checking GitHub URL configuration..."
if grep -q "YOUR_USERNAME" kiosk-common.nix; then
    echo "⚠️  WARNING: You still need to update YOUR_USERNAME in kiosk-common.nix"
    echo "   Edit line ~30 and change 'github:YOUR_USERNAME/kiosk-fleet' to your actual repo"
else
    echo "✅ GitHub URL appears to be configured"
fi

# Check for required files
echo ""
echo "📁 Checking required files..."
required_files=("flake.nix" "kiosk-common.nix" "hardware-configuration.nix" "README.md")
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file missing"
    fi
done

# Validate kiosk-common.nix for the ExperienceCo URL
echo ""
echo "🌐 Checking homepage URL..."
if grep -q "https://login.experienceco.com" kiosk-common.nix; then
    echo "✅ Homepage correctly set to https://login.experienceco.com"
else
    echo "⚠️  WARNING: ExperienceCo URL not found in kiosk-common.nix"
fi

echo ""
echo "✨ Validation complete!"
echo ""
echo "Next steps:"
echo "1. Update YOUR_USERNAME in kiosk-common.nix if not done yet"
echo "2. Commit and push to your GitHub repository"
echo "3. Follow QUICKSTART.md to deploy your first kiosk"
