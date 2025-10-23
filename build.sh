#!/usr/bin/env bash

# Simple build script for testing without Nix flakes

echo "Building CSS..."
tailwindcss -i ./css/input.css -o ./css/style.css

echo "The site structure is ready!"
echo "To build with Hakyll, you'll need:"
echo "1. GHC and Cabal installed"
echo "2. Run: cabal run site build"
echo "3. The site will be generated in the 'docs' directory"
echo ""
echo "Directory structure:"
find . -type f -name "*.hs" -o -name "*.cabal" -o -name "*.typ" -o -name "*.html" | head -20
