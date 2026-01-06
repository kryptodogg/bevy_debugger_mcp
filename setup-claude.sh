#!/bin/bash

# Universal setup script for bevy-debugger-mcp
# Supports: Claude (Code/Desktop), Cline, Roo Code, Cursor, VS Code, Gemini/Qwen/Codex CLI
# Run this after installing via any method (cargo, brew, manual)

set -e

echo "Setting up bevy-debugger-mcp..."

# Find the bevy-debugger-mcp binary
BINARY_PATH=""

# Check common installation locations
if command -v bevy-debugger-mcp &> /dev/null; then
    BINARY_PATH=$(which bevy-debugger-mcp)
    echo "✅ Found bevy-debugger-mcp at: $BINARY_PATH"
elif [ -f "$HOME/.cargo/bin/bevy-debugger-mcp" ]; then
    BINARY_PATH="$HOME/.cargo/bin/bevy-debugger-mcp"
    echo "✅ Found bevy-debugger-mcp at: $BINARY_PATH"
elif [ -f "/usr/local/bin/bevy-debugger-mcp" ]; then
    BINARY_PATH="/usr/local/bin/bevy-debugger-mcp"
    echo "✅ Found bevy-debugger-mcp at: $BINARY_PATH"
elif [ -f "/opt/homebrew/bin/bevy-debugger-mcp" ]; then
    BINARY_PATH="/opt/homebrew/bin/bevy-debugger-mcp"
    echo "✅ Found bevy-debugger-mcp at: $BINARY_PATH"
else
    echo "❌ bevy-debugger-mcp not found. Please install it first:"
    echo "  cargo install bevy_debugger_mcp"
    echo "  or"
    echo "  brew install bevy-debugger-mcp"
    exit 1
fi

# Create symlinks for compatibility
echo "Creating compatibility symlinks..."
mkdir -p ~/.local/bin
ln -sf "$BINARY_PATH" ~/.local/bin/bevy-debugger-mcp

# Also ensure it's in ~/.cargo/bin for consistency
if [ ! -f "$HOME/.cargo/bin/bevy-debugger-mcp" ] && [ "$BINARY_PATH" != "$HOME/.cargo/bin/bevy-debugger-mcp" ]; then
    mkdir -p ~/.cargo/bin
    ln -sf "$BINARY_PATH" ~/.cargo/bin/bevy-debugger-mcp
fi

# Define the common config block
CONFIG_JSON=$(cat << EOF
    "bevy-debugger-mcp": {
      "command": "$BINARY_PATH",
      "args": ["stdio"],
      "env": {
        "RUST_LOG": "info",
        "BEVY_BRP_HOST": "127.0.0.1",
        "BEVY_BRP_PORT": "15702"
      }
    }
EOF
)

FULL_CONFIG_JSON=$(cat << EOF
{
  "mcpServers": {
$CONFIG_JSON
  }
}
EOF
)

# Function to check and print instructions for a config file
check_config() {
    local name="$1"
    local config_path="$2"

    if [ -f "$config_path" ]; then
        echo "--------- $name ---------"
        echo "Found config at: $config_path"
        if grep -q "bevy-debugger-mcp" "$config_path"; then
            echo "⚠️  bevy-debugger-mcp already configured in $name"
        else
            echo "📝 Add the following to 'mcpServers' in your $name config:"
            echo "$CONFIG_JSON"
        fi
        echo ""
    fi
}

echo ""
echo "=== Configuration Check ==="
echo ""

# 1. Claude Code
CLAUDE_CODE_CONFIG="$HOME/.claude/mcp_settings.json"
if [ ! -f "$CLAUDE_CODE_CONFIG" ]; then
    mkdir -p ~/.claude
    echo "--------- Claude Code ---------"
    echo "Creating new config at: $CLAUDE_CODE_CONFIG"
    echo "$FULL_CONFIG_JSON" > "$CLAUDE_CODE_CONFIG"
    echo "✅ Created Claude Code config"
    echo ""
else
    check_config "Claude Code" "$CLAUDE_CODE_CONFIG"
fi

# 2. Claude Desktop (macOS)
CLAUDE_DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
check_config "Claude Desktop (macOS)" "$CLAUDE_DESKTOP_CONFIG"

# 3. Cline (VS Code Extension)
# macOS
CLINE_CONFIG_MAC="$HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
check_config "Cline (macOS)" "$CLINE_CONFIG_MAC"
# Linux
CLINE_CONFIG_LINUX="$HOME/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
check_config "Cline (Linux)" "$CLINE_CONFIG_LINUX"
# Windows (approximate via WSL/Git Bash if applicable, but usually $APPDATA)

# 4. Roo Code (VS Code Extension)
# macOS
ROO_CONFIG_MAC="$HOME/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/cline_mcp_settings.json"
check_config "Roo Code (macOS)" "$ROO_CONFIG_MAC"
# Linux
ROO_CONFIG_LINUX="$HOME/.config/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/cline_mcp_settings.json"
check_config "Roo Code (Linux)" "$ROO_CONFIG_LINUX"


echo "=== Manual Configuration Instructions ==="
echo ""
echo "If your tool's config was not found automatically, use the JSON below."
echo "Applicable for: VS Code, Cursor, Gemini CLI, Qwen CLI, Codex CLI, etc."
echo ""
echo "$FULL_CONFIG_JSON"
echo ""
echo "Specific Instructions:"
echo "• VS Code (with MCP extension): Add to your User or Workspace settings.json under 'mcp.servers'."
echo "• Cursor IDE: Go to Settings > Features > MCP > Add New MCP Server."
echo "  - Name: bevy-debugger-mcp"
echo "  - Type: stdio"
echo "  - Command: $BINARY_PATH"
echo "  - Args: stdio"
echo "  - Env: RUST_LOG=info, BEVY_BRP_HOST=127.0.0.1, BEVY_BRP_PORT=15702"
echo ""
echo "✅ Setup complete! Symlinks created at ~/.local/bin/bevy-debugger-mcp"
