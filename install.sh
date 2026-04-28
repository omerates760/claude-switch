#!/usr/bin/env bash
# Installer for claude-switch.
# Places the script at ~/.claude-profiles/claude-switch and symlinks it into PATH.

set -euo pipefail

SCRIPT_NAME="claude-switch"
INSTALL_HOME="$HOME/.claude-profiles"
INSTALL_PATH="$INSTALL_HOME/$SCRIPT_NAME"
RAW_URL="https://raw.githubusercontent.com/omerates760/claude-switch/main/$SCRIPT_NAME"

c_red()    { printf '\033[31m%s\033[0m\n' "$*"; }
c_green()  { printf '\033[32m%s\033[0m\n' "$*"; }
c_yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

die() { c_red "Error: $*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || die "claude-switch requires macOS."

mkdir -p "$INSTALL_HOME"
chmod 700 "$INSTALL_HOME"

# Source: local copy if running from a checkout, otherwise download.
if [[ -f "$(dirname "$0")/$SCRIPT_NAME" ]]; then
    cp "$(dirname "$0")/$SCRIPT_NAME" "$INSTALL_PATH"
    c_green "Installed from local checkout → $INSTALL_PATH"
else
    if ! command -v curl >/dev/null 2>&1; then
        die "curl is required to download the script."
    fi
    c_yellow "Downloading from $RAW_URL"
    curl -fsSL "$RAW_URL" -o "$INSTALL_PATH"
    c_green "Installed → $INSTALL_PATH"
fi

chmod +x "$INSTALL_PATH"

# Find a writable directory in PATH and symlink there.
CANDIDATES=(
    "/opt/homebrew/bin"
    "/usr/local/bin"
    "$HOME/.local/bin"
    "$HOME/bin"
)

LINK_DIR=""
for d in "${CANDIDATES[@]}"; do
    if [[ -d "$d" && -w "$d" ]]; then
        LINK_DIR="$d"
        break
    fi
done

if [[ -z "$LINK_DIR" ]]; then
    mkdir -p "$HOME/.local/bin"
    LINK_DIR="$HOME/.local/bin"
    c_yellow "Created $LINK_DIR — make sure it is in your PATH."
fi

ln -sf "$INSTALL_PATH" "$LINK_DIR/$SCRIPT_NAME"
c_green "Symlinked → $LINK_DIR/$SCRIPT_NAME"

if ! command -v "$SCRIPT_NAME" >/dev/null 2>&1; then
    c_yellow "$LINK_DIR is not in your PATH. Add this to your shell rc:"
    echo "    export PATH=\"$LINK_DIR:\$PATH\""
fi

c_green "Done. Try: claude-switch --help"
