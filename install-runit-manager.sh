#!/bin/bash
# Installer for Runit Service Manager

set -e

VERSION="1.0"
SCRIPT_NAME="runit-manager"
INSTALL_DIR="/usr/local/bin"
MAN_DIR="/usr/local/share/man/man1"

echo -e "\033[0;36m╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "\033[0;36m║                                                           ║${NC}"
echo -e "\033[0;36m║      Runit Service Manager Installer v$VERSION             ║${NC}"
echo -e "\033[0;36m║                                                           ║${NC}"
echo -e "\033[0;36m╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root for installation
if [ "$EUID" -eq 0 ]; then
    echo -e "\033[1;33m⚠ Running as root for installation${NC}"
fi

# Check if runit is installed
if ! command -v sv &> /dev/null; then
    echo -e "\033[0;31m✗ Error: runit not found. Please install runit first.${NC}"
    echo "  On Void Linux: sudo xbps-install runit"
    echo "  On Debian/Ubuntu: sudo apt-get install runit"
    echo "  On Arch: sudo pacman -S runit"
    exit 1
else
    echo -e "\033[0;32m✓ runit found${NC}"
fi

# Create temporary file
TEMP_FILE=$(mktemp)

# Download or copy the script
echo -e "\033[0;34m→ Preparing installation...${NC}"

# If the script is in the same directory, use it
if [ -f "./runit-manager.sh" ]; then
    cat "./runit-manager.sh" > "$TEMP_FILE"
    echo -e "\033[0;32m✓ Using local script${NC}"
else
    # Otherwise, create it from the content above
    # You would normally curl or wget it from a repository
    echo -e "\033[1;33m⚠ Please place the runit-manager.sh script in the current directory${NC}"
    exit 1
fi

# Make script executable
chmod +x "$TEMP_FILE"

# Install the script
echo -e "\033[0;34m→ Installing to $INSTALL_DIR/$SCRIPT_NAME...${NC}"
if [ -w "$INSTALL_DIR" ] || [ "$EUID" -eq 0 ]; then
    cp "$TEMP_FILE" "$INSTALL_DIR/$SCRIPT_NAME"
    chmod 755 "$INSTALL_DIR/$SCRIPT_NAME"
    echo -e "\033[0;32m✓ Script installed successfully${NC}"
else
    echo -e "\033[1;33m⚠ Need sudo to install to $INSTALL_DIR${NC}"
    sudo cp "$TEMP_FILE" "$INSTALL_DIR/$SCRIPT_NAME"
    sudo chmod 755 "$INSTALL_DIR/$SCRIPT_NAME"
    echo -e "\033[0;32m✓ Script installed successfully with sudo${NC}"
fi

# Clean up temp file
rm -f "$TEMP_FILE"

# Create man page (optional)
echo -e "\033[0;34m→ Creating man page...${NC}"
if [ -w "$MAN_DIR" ] || [ "$EUID" -eq 0 ]; then
    mkdir -p "$MAN_DIR"
    cat > "$MAN_DIR/runit-manager.1" << 'EOF'
.TH RUNIT-MANAGER 1 "2024-01-01" "1.0" "Runit Service Manager"
.SH NAME
runit-manager \- Manage runit services interactively
.SH SYNOPSIS
.B runit-manager
[\fIOPTIONS\fR]
.SH DESCRIPTION
Runit Service Manager provides an interactive menu and command-line
interface for managing runit services.
.SH OPTIONS
.TP
\fB-h, --help\fR
Show help message
.TP
\fB-v, --version\fR
Show version information
.TP
\fB-l, --list\fR
List all available services
.TP
\fB-e, --enabled\fR
List enabled services
.TP
\fB-s, --status\fR SERVICE
Show status of a service
.TP
\fB--enable\fR SERVICE
Enable a service
.TP
\fB--disable\fR SERVICE
Disable a service
.TP
\fB--start\fR SERVICE
Start a service
.TP
\fB--stop\fR SERVICE
Stop a service
.TP
\fB--restart\fR SERVICE
Restart a service
.TP
\fB--logs\fR SERVICE
Show logs for a service
.TP
\fB--info\fR SERVICE
Show detailed info for a service
.SH EXAMPLES
.B runit-manager
.P
Run interactive menu
.P
.B runit-manager --enable nginx
.P
Enable the nginx service
.SH AUTHOR
Written by [Your Name]
.SH SEE ALSO
.BR sv (8),
.BR runsv (8),
.BR runsvdir (8)
EOF
    echo -e "\033[0;32m✓ Man page created${NC}"
else
    echo -e "\033[1;33m⚠ Could not create man page (permission denied)${NC}"
fi

# Create bash completion (optional)
echo -e "\033[0;34m→ Setting up bash completion...${NC}"
if [ -d "/etc/bash_completion.d" ] || [ "$EUID" -eq 0 ]; then
    sudo tee "/etc/bash_completion.d/runit-manager" > /dev/null << 'EOF'
_runit_manager_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--help --version --list --enabled --status --enable --disable --start --stop --restart --logs --info"
    
    case "${prev}" in
        --enable|--disable|--start|--stop|--restart|--logs|--info|--status)
            # Get list of services from /etc/sv
            local services=$(ls /etc/sv/ 2>/dev/null)
            COMPREPLY=( $(compgen -W "${services}" -- ${cur}) )
            return 0
            ;;
        *)
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            return 0
            ;;
    esac
}
complete -F _runit_manager_completion runit-manager
EOF
    echo -e "\033[0;32m✓ Bash completion installed${NC}"
else
    echo -e "\033[1;33m⚠ Could not install bash completion (permission denied)${NC}"
fi

# Check if script is in PATH
if command -v runit-manager &> /dev/null; then
    echo -e "\033[0;32m✓ runit-manager is now available system-wide!${NC}"
else
    echo -e "\033[1;33m⚠ Please ensure $INSTALL_DIR is in your PATH${NC}"
    echo "  You can add it by adding this to ~/.bashrc:"
    echo "  export PATH=\$PATH:$INSTALL_DIR"
fi

echo ""
echo -e "\033[0;32m╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "\033[0;32m║                    Installation Complete!               ║${NC}"
echo -e "\033[0;32m╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "\033[0;34m📖 Usage:${NC}"
echo "  runit-manager           # Launch interactive menu"
echo "  runit-manager --help    # Show all options"
echo ""
echo -e "\033[0;34m🔧 Quick commands:${NC}"
echo "  runit-manager --list          # List all services"
echo "  runit-manager --enable nginx  # Enable nginx"
echo "  runit-manager --status sshd   # Check sshd status"
echo ""
echo -e "\033[1;33m⚠ Some commands require sudo:${NC}"
echo "  sudo runit-manager --disable service"
echo "  sudo runit-manager --start service"
echo ""