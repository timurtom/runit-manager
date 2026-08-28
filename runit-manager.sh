#!/bin/bash
# runit-manager - Runit Service Manager
# Version: 1.0
# Installed location: /usr/local/bin/runit-manager

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Version info
VERSION="1.0"

# Service directories
SERVICES_DIR="/etc/sv"
SERVICE_LINK_DIR="/var/service"

# If /var/service doesn't exist, try /run/runit/service
if [ ! -d "$SERVICE_LINK_DIR" ]; then
    SERVICE_LINK_DIR="/run/runit/service"
fi

# Check if runit is installed
if ! command -v sv &> /dev/null; then
    echo -e "${RED}Error: sv command not found. Is runit installed?${NC}"
    exit 1
fi

# Check if services directory exists
if [ ! -d "$SERVICES_DIR" ]; then
    echo -e "${RED}Error: $SERVICES_DIR not found. Is runit properly installed?${NC}"
    exit 1
fi

# Check if running with appropriate privileges
check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}⚠ Some operations require sudo privileges${NC}"
        echo -e "${YELLOW}  - Enabling/disabling services${NC}"
        echo -e "${YELLOW}  - Starting/stopping services${NC}"
        echo -e "${YELLOW}  - Viewing status for some services${NC}"
        echo ""
    fi
}

# Function to check if service is enabled
is_enabled() {
    local service="$1"
    if [ -L "$SERVICE_LINK_DIR/$service" ] && [ -e "$SERVICE_LINK_DIR/$service" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check if service is running
is_running() {
    local service="$1"
    local status=$(sv status "$service" 2>/dev/null)
    if [[ "$status" == run:* ]]; then
        return 0
    else
        return 1
    fi
}

# Function to list available services
list_available() {
    echo -e "\n${BLUE}📁 Available services in $SERVICES_DIR:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    local count=0
    local enabled=0
    local disabled=0
    
    for service in "$SERVICES_DIR"/*; do
        if [ -d "$service" ]; then
            local name=$(basename "$service")
            if is_enabled "$name"; then
                echo -e "  ${GREEN}✓${NC} $name ${GREEN}(enabled)${NC}"
                ((enabled++))
            else
                echo -e "  ${YELLOW}○${NC} $name ${YELLOW}(disabled)${NC}"
                ((disabled++))
            fi
            ((count++))
        fi
    done
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Total: ${GREEN}$enabled enabled${NC}, ${YELLOW}$disabled disabled${NC}, ${CYAN}$count total${NC}"
    echo ""
}

# Function to list enabled services
list_enabled() {
    echo -e "\n${BLUE}⚡ Enabled services in $SERVICE_LINK_DIR:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    local count=0
    local running=0
    local stopped=0
    
    if [ -d "$SERVICE_LINK_DIR" ]; then
        for service in "$SERVICE_LINK_DIR"/*; do
            if [ -L "$service" ] && [ -e "$service" ]; then
                local name=$(basename "$service")
                if is_running "$name"; then
                    echo -e "  ${GREEN}▶${NC} $name ${GREEN}(running)${NC}"
                    ((running++))
                else
                    echo -e "  ${YELLOW}◼${NC} $name ${YELLOW}(stopped)${NC}"
                    ((stopped++))
                fi
                ((count++))
            fi
        done
    fi
    
    if [ $count -eq 0 ]; then
        echo -e "  ${RED}No enabled services found${NC}"
    fi
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Total: ${GREEN}$running running${NC}, ${YELLOW}$stopped stopped${NC}, ${CYAN}$count total${NC}"
    echo ""
}

# Function to enable a service
enable_service() {
    echo -e "\n${CYAN}🔗 Enable Service${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Available services (disabled only):"
    local services=()
    local i=1
    for service in "$SERVICES_DIR"/*; do
        if [ -d "$service" ]; then
            local name=$(basename "$service")
            if ! is_enabled "$name"; then
                printf "  ${GREEN}%3d${NC}) %s\n" "$i" "$name"
                services+=("$name")
                ((i++))
            fi
        fi
    done
    
    if [ ${#services[@]} -eq 0 ]; then
        echo -e "${RED}No disabled services available to enable.${NC}"
        return
    fi
    
    echo ""
    read -p "Enter the service name or number to enable: " input
    
    # Check if input is a number
    if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le ${#services[@]} ]; then
        service_name="${services[$((input-1))]}"
    else
        service_name="$input"
    fi
    
    # Verify service exists
    if [ ! -d "$SERVICES_DIR/$service_name" ]; then
        echo -e "${RED}✗ Error: Service '$service_name' not found in $SERVICES_DIR${NC}"
        return
    fi
    
    # Check if already enabled
    if is_enabled "$service_name"; then
        echo -e "${YELLOW}⚠ Service '$service_name' is already enabled.${NC}"
        return
    fi
    
    # Create symlink
    echo -e "${YELLOW}→ Enabling $service_name...${NC}"
    if sudo ln -s "$SERVICES_DIR/$service_name" "$SERVICE_LINK_DIR/" 2>/dev/null; then
        echo -e "${GREEN}✓ Service '$service_name' enabled successfully!${NC}"
        # Check if it started
        sleep 1
        if is_running "$service_name"; then
            echo -e "${GREEN}✓ Service is now running${NC}"
        else
            echo -e "${YELLOW}⚠ Service enabled but may not be running. Check with 'sv status $service_name'${NC}"
        fi
    else
        echo -e "${RED}✗ Error: Failed to enable service '$service_name'${NC}"
        echo -e "${YELLOW}  Try running with sudo: sudo runit-manager${NC}"
    fi
}

# Function to disable a service
disable_service() {
    echo -e "\n${CYAN}🔗 Disable Service${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ ! -d "$SERVICE_LINK_DIR" ] || [ -z "$(ls -A "$SERVICE_LINK_DIR" 2>/dev/null)" ]; then
        echo -e "${RED}No enabled services found.${NC}"
        return
    fi
    
    echo -e "Enabled services:"
    local services=()
    local i=1
    for service in "$SERVICE_LINK_DIR"/*; do
        if [ -L "$service" ] && [ -e "$service" ]; then
            local name=$(basename "$service")
            printf "  ${GREEN}%3d${NC}) %s" "$i" "$name"
            if is_running "$name"; then
                echo -e " ${GREEN}(running)${NC}"
            else
                echo -e " ${YELLOW}(stopped)${NC}"
            fi
            services+=("$name")
            ((i++))
        fi
    done
    
    echo ""
    read -p "Enter the service name or number to disable: " input
    
    # Check if input is a number
    if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le ${#services[@]} ]; then
        service_name="${services[$((input-1))]}"
    else
        service_name="$input"
    fi
    
    # Verify service is enabled
    if ! is_enabled "$service_name"; then
        echo -e "${RED}✗ Error: Service '$service_name' is not enabled.${NC}"
        return
    fi
    
    # Stop the service first
    echo -e "${YELLOW}→ Stopping $service_name...${NC}"
    sudo sv stop "$service_name" 2>/dev/null
    
    # Remove symlink
    echo -e "${YELLOW}→ Disabling $service_name...${NC}"
    if sudo rm "$SERVICE_LINK_DIR/$service_name" 2>/dev/null; then
        echo -e "${GREEN}✓ Service '$service_name' disabled successfully!${NC}"
    else
        echo -e "${RED}✗ Error: Failed to disable service '$service_name'${NC}"
        echo -e "${YELLOW}  Try running with sudo: sudo runit-manager${NC}"
    fi
}

# Function to start a service
start_service() {
    echo -e "\n${CYAN}▶ Start Service${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Enter the service name to start: " service_name
    
    if ! is_enabled "$service_name"; then
        echo -e "${RED}✗ Error: Service '$service_name' is not enabled. Enable it first.${NC}"
        return
    fi
    
    if is_running "$service_name"; then
        echo -e "${YELLOW}⚠ Service '$service_name' is already running.${NC}"
        return
    fi
    
    echo -e "${YELLOW}→ Starting $service_name...${NC}"
    if sudo sv start "$service_name" 2>/dev/null; then
        echo -e "${GREEN}✓ Service '$service_name' started!${NC}"
    else
        echo -e "${RED}✗ Error: Failed to start service '$service_name'${NC}"
        echo -e "${YELLOW}  Try running with sudo: sudo runit-manager${NC}"
    fi
}

# Function to stop a service
stop_service() {
    echo -e "\n${CYAN}■ Stop Service${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Enter the service name to stop: " service_name
    
    if ! is_enabled "$service_name"; then
        echo -e "${RED}✗ Error: Service '$service_name' is not enabled.${NC}"
        return
    fi
    
    if ! is_running "$service_name"; then
        echo -e "${YELLOW}⚠ Service '$service_name' is already stopped.${NC}"
        return
    fi
    
    echo -e "${YELLOW}→ Stopping $service_name...${NC}"
    if sudo sv stop "$service_name" 2>/dev/null; then
        echo -e "${GREEN}✓ Service '$service_name' stopped!${NC}"
    else
        echo -e "${RED}✗ Error: Failed to stop service '$service_name'${NC}"
        echo -e "${YELLOW}  Try running with sudo: sudo runit-manager${NC}"
    fi
}

# Function to restart a service
restart_service() {
    echo -e "\n${CYAN}↻ Restart Service${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Enter the service name to restart: " service_name
    
    if ! is_enabled "$service_name"; then
        echo -e "${RED}✗ Error: Service '$service_name' is not enabled.${NC}"
        return
    fi
    
    echo -e "${YELLOW}→ Restarting $service_name...${NC}"
    if sudo sv restart "$service_name" 2>/dev/null; then
        echo -e "${GREEN}✓ Service '$service_name' restarted!${NC}"
    else
        echo -e "${RED}✗ Error: Failed to restart service '$service_name'${NC}"
        echo -e "${YELLOW}  Try running with sudo: sudo runit-manager${NC}"
    fi
}

# Function to show service status
show_status() {
    echo -e "\n${CYAN}📊 Service Status${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Enter the service name to check: " service_name
    
    if ! is_enabled "$service_name"; then
        echo -e "${RED}✗ Error: Service '$service_name' is not enabled.${NC}"
        return
    fi
    
    echo -e "${BLUE}Status for $service_name:${NC}"
    sv status "$service_name" 2>/dev/null || echo -e "${RED}Failed to get status (try with sudo)${NC}"
    echo ""
}

# Function to show service logs
show_logs() {
    echo -e "\n${CYAN}📝 Service Logs${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Enter the service name to view logs: " service_name
    
    if ! is_enabled "$service_name"; then
        echo -e "${RED}✗ Error: Service '$service_name' is not enabled.${NC}"
        return
    fi
    
    local log_dir="$SERVICES_DIR/$service_name/log"
    if [ -d "$log_dir" ]; then
        echo -e "${BLUE}Last 20 lines of logs for $service_name:${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        if [ -f "$log_dir/current" ]; then
            tail -n 20 "$log_dir/current" 2>/dev/null || echo -e "${YELLOW}No log entries found${NC}"
        else
            echo -e "${YELLOW}No log file found${NC}"
        fi
    else
        echo -e "${YELLOW}No log directory found for $service_name${NC}"
        echo -e "${YELLOW}Tip: Some services log to syslog instead${NC}"
    fi
    echo ""
}

# Function to show service info
service_info() {
    echo -e "\n${CYAN}ℹ Service Information${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Enter the service name to inspect: " service_name
    
    if [ ! -d "$SERVICES_DIR/$service_name" ]; then
        echo -e "${RED}✗ Error: Service '$service_name' not found.${NC}"
        return
    fi
    
    echo -e "${BLUE}Service:${NC} $service_name"
    echo -e "${BLUE}Status:${NC} $(is_enabled "$service_name" && echo "${GREEN}Enabled${NC}" || echo "${YELLOW}Disabled${NC}")"
    if is_enabled "$service_name"; then
        echo -e "${BLUE}Running:${NC} $(is_running "$service_name" && echo "${GREEN}Yes${NC}" || echo "${RED}No${NC}")"
        echo -e "${BLUE}Location:${NC} $SERVICE_LINK_DIR/$service_name -> $(readlink "$SERVICE_LINK_DIR/$service_name")"
    fi
    echo -e "${BLUE}Source:${NC} $SERVICES_DIR/$service_name"
    
    if [ -f "$SERVICES_DIR/$service_name/run" ]; then
        echo -e "${BLUE}Run script:${NC} $(head -1 "$SERVICES_DIR/$service_name/run")"
    fi
    
    if [ -d "$SERVICES_DIR/$service_name/log" ]; then
        echo -e "${BLUE}Logging:${NC} ${GREEN}Configured${NC}"
    else
        echo -e "${BLUE}Logging:${NC} ${YELLOW}Not configured${NC}"
    fi
    echo ""
}

# Function to show help
show_help() {
    echo -e "${CYAN}Runit Service Manager v$VERSION${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Description:${NC} Manage runit services interactively"
    echo -e "${GREEN}Usage:${NC} runit-manager [OPTIONS]"
    echo ""
    echo -e "${BLUE}Options:${NC}"
    echo -e "  ${GREEN}-h, --help${NC}     Show this help message"
    echo -e "  ${GREEN}-v, --version${NC}  Show version information"
    echo -e "  ${GREEN}-l, --list${NC}     List all available services"
    echo -e "  ${GREEN}-e, --enabled${NC}  List enabled services"
    echo -e "  ${GREEN}-s, --status${NC}   Show status of a service (requires name)"
    echo "  --enable NAME      Enable a service"
    echo "  --disable NAME     Disable a service"
    echo "  --start NAME       Start a service"
    echo "  --stop NAME        Stop a service"
    echo "  --restart NAME     Restart a service"
    echo "  --logs NAME        Show logs for a service"
    echo "  --info NAME        Show detailed info for a service"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  runit-manager              # Interactive menu"
    echo "  runit-manager --enable nginx"
    echo "  runit-manager --list"
    echo "  sudo runit-manager --disable sshd"
    echo ""
    echo -e "${YELLOW}Note:${NC} Some operations require sudo privileges"
}

# Main menu function
show_menu() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                           ║${NC}"
    echo -e "${CYAN}║      🔧 Runit Service Manager v$VERSION                    ║${NC}"
    echo -e "${CYAN}║                                                           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo -e "${BLUE}📂 Service Directories:${NC}"
    echo -e "  Source: ${YELLOW}$SERVICES_DIR${NC}"
    echo -e "  Target: ${YELLOW}$SERVICE_LINK_DIR${NC}"
    echo ""
    echo -e "${GREEN} 1${NC}) ${MAGENTA}📁${NC} View available services"
    echo -e "${GREEN} 2${NC}) ${MAGENTA}⚡${NC} View enabled services"
    echo -e "${GREEN} 3${NC}) ${MAGENTA}🔗${NC} Enable a service"
    echo -e "${GREEN} 4${NC}) ${MAGENTA}🔗${NC} Disable a service"
    echo -e "${GREEN} 5${NC}) ${MAGENTA}▶${NC}  Start a service"
    echo -e "${GREEN} 6${NC}) ${MAGENTA}■${NC}  Stop a service"
    echo -e "${GREEN} 7${NC}) ${MAGENTA}↻${NC}  Restart a service"
    echo -e "${GREEN} 8${NC}) ${MAGENTA}📊${NC} Show service status"
    echo -e "${GREEN} 9${NC}) ${MAGENTA}📝${NC} View service logs"
    echo -e "${GREEN}10${NC}) ${MAGENTA}ℹ${NC}  Service information"
    echo -e "${GREEN} 0${NC}) ${MAGENTA}🚪${NC} Exit"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    check_privileges
    read -p "Choose an option: " choice
    echo ""
    
    case $choice in
        1) list_available ;;
        2) list_enabled ;;
        3) enable_service ;;
        4) disable_service ;;
        5) start_service ;;
        6) stop_service ;;
        7) restart_service ;;
        8) show_status ;;
        9) show_logs ;;
        10) service_info ;;
        0) echo -e "${GREEN}👋 Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}✗ Invalid option. Please try again.${NC}"; sleep 1 ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Command-line argument handling
handle_args() {
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            echo "runit-manager version $VERSION"
            exit 0
            ;;
        -l|--list)
            list_available
            exit 0
            ;;
        -e|--enabled)
            list_enabled
            exit 0
            ;;
        -s|--status)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Service name required${NC}"
                echo "Usage: runit-manager --status SERVICE"
                exit 1
            fi
            service_name="$2"
            if is_enabled "$service_name"; then
                sv status "$service_name"
            else
                echo -e "${RED}Service '$service_name' is not enabled${NC}"
            fi
            exit 0
            ;;
        --enable)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Service name required${NC}"
                echo "Usage: runit-manager --enable SERVICE"
                exit 1
            fi
            service_name="$2"
            if [ ! -d "$SERVICES_DIR/$service_name" ]; then
                echo -e "${RED}Service '$service_name' not found${NC}"
                exit 1
            fi
            if is_enabled "$service_name"; then
                echo -e "${YELLOW}Service '$service_name' is already enabled${NC}"
                exit 0
            fi
            echo -e "${YELLOW}Enabling $service_name...${NC}"
            sudo ln -s "$SERVICES_DIR/$service_name" "$SERVICE_LINK_DIR/" && \
                echo -e "${GREEN}Service '$service_name' enabled successfully${NC}" || \
                echo -e "${RED}Failed to enable service${NC}"
            exit 0
            ;;
        --disable)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Service name required${NC}"
                echo "Usage: runit-manager --disable SERVICE"
                exit 1
            fi
            service_name="$2"
            if ! is_enabled "$service_name"; then
                echo -e "${RED}Service '$service_name' is not enabled${NC}"
                exit 1
            fi
            echo -e "${YELLOW}Stopping and disabling $service_name...${NC}"
            sudo sv stop "$service_name" 2>/dev/null
            sudo rm "$SERVICE_LINK_DIR/$service_name" && \
                echo -e "${GREEN}Service '$service_name' disabled successfully${NC}" || \
                echo -e "${RED}Failed to disable service${NC}"
            exit 0
            ;;
        --start)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Service name required${NC}"
                echo "Usage: runit-manager --start SERVICE"
                exit 1
            fi
            service_name="$2"
            if ! is_enabled "$service_name"; then
                echo -e "${RED}Service '$service_name' is not enabled${NC}"
                exit 1
            fi
            echo -e "${YELLOW}Starting $service_name...${NC}"
            sudo sv start "$service_name" && \
                echo -e "${GREEN}Service '$service_name' started${NC}" || \
                echo -e "${RED}Failed to start service${NC}"
            exit 0
            ;;
        --stop)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Service name required${NC}"
                echo "Usage: runit-manager --stop SERVICE"
                exit 1
            fi
            service_name="$2"
            if ! is_enabled "$service_name"; then
                echo -e "${RED}Service '$service_name' is not enabled${NC}"
                exit 1
            fi
            echo -e "${YELLOW}Stopping $service_name...${NC}"
            sudo sv stop "$service_name" && \
                echo -e "${GREEN}Service '$service_name' stopped${NC}" || \
                echo -e "${RED}Failed to stop service${NC}"
            exit 0
            ;;
        --restart)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Service name required${NC}"
                echo "Usage: runit-manager --restart SERVICE"
                exit 1
            fi
            service_name="$2"
            if ! is_enabled "$service_name"; then
                echo -e "${RED}Service '$service_name' is not enabled${NC}"
                exit 1
            fi
            echo -e "${YELLOW}Restarting $service_name...${NC}"
            sudo sv restart "$service_name" && \
                echo -e "${GREEN}Service '$service_name' restarted${NC}" || \
                echo -e "${RED}Failed to restart service${NC}"
            exit 0
            ;;
        --logs)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Service name required${NC}"
                echo "Usage: runit-manager --logs SERVICE"
                exit 1
            fi
            service_name="$2"
            if ! is_enabled "$service_name"; then
                echo -e "${RED}Service '$service_name' is not enabled${NC}"
                exit 1
            fi
            log_dir="$SERVICES_DIR/$service_name/log"
            if [ -f "$log_dir/current" ]; then
                tail -n 20 "$log_dir/current"
            else
                echo -e "${YELLOW}No logs found for $service_name${NC}"
            fi
            exit 0
            ;;
        --info)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Service name required${NC}"
                echo "Usage: runit-manager --info SERVICE"
                exit 1
            fi
            service_name="$2"
            if [ ! -d "$SERVICES_DIR/$service_name" ]; then
                echo -e "${RED}Service '$service_name' not found${NC}"
                exit 1
            fi
            echo -e "${BLUE}Service:${NC} $service_name"
            echo -e "${BLUE}Status:${NC} $(is_enabled "$service_name" && echo "Enabled" || echo "Disabled")"
            if is_enabled "$service_name"; then
                echo -e "${BLUE}Running:${NC} $(is_running "$service_name" && echo "Yes" || echo "No")"
                echo -e "${BLUE}Link:${NC} $SERVICE_LINK_DIR/$service_name -> $(readlink "$SERVICE_LINK_DIR/$service_name")"
            fi
            echo -e "${BLUE}Source:${NC} $SERVICES_DIR/$service_name"
            exit 0
            ;;
        "")
            show_menu
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Try 'runit-manager --help' for usage"
            exit 1
            ;;
    esac
}

# Trap Ctrl+C
trap 'echo -e "\n${RED}Exiting...${NC}"; exit 0' INT

# Main execution
if [ $# -gt 0 ]; then
    handle_args "$@"
else
    show_menu
fi