#!/bin/bash
# uninstall-runit-manager.sh

echo -e "\033[0;31mUninstalling Runit Service Manager...${NC}"

# Remove main script
sudo rm -f /usr/local/bin/runit-manager

# Remove man page
sudo rm -f /usr/local/share/man/man1/runit-manager.1

# Remove bash completion
sudo rm -f /etc/bash_completion.d/runit-manager

# Remove any other files
sudo rm -rf ~/.config/runit-manager  # If it exists

echo -e "\033[0;32m✓ Uninstall complete${NC}"