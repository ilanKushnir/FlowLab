#!/bin/bash

# =============================================================================
# FlowLab - Your Personal Automation Laboratory
# =============================================================================

set -euo pipefail

# Load configuration
if [[ ! -f "config.env" ]]; then
    echo "❌ config.env file not found!"
    echo "Please create config.env from the template"
    exit 1
fi

source config.env

# Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Pretty print functions
print_header() {
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}${CYAN}    ███████╗██╗      ██████╗ ██╗    ██╗██╗      █████╗ ██████╗                                 ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${CYAN}    ██╔════╝██║     ██╔═══██╗██║    ██║██║     ██╔══██╗██╔══██╗                                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${CYAN}    █████╗  ██║     ██║   ██║██║ █╗ ██║██║     ███████║██████╔╝                                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${CYAN}    ██╔══╝  ██║     ██║   ██║██║███╗██║██║     ██╔══██║██╔══██╗                                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${CYAN}    ██║     ███████╗╚██████╔╝╚███╔███╔╝███████╗██║  ██║██████╔╝                                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${CYAN}    ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═════╝                                 ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${WHITE}                                                                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${WHITE}                    🧪 Your Personal Automation Laboratory 🧪                                   ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${WHITE}                         Where workflows come to life!                                          ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Cloudflare tunnel setup removed - no longer supported

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        print_error "Ansible is not installed!"
        echo "Install it with: brew install ansible (macOS) or pip install ansible"
        exit 1
    fi
    
    # Check SSH key
    if [[ ! -f "${PI_SSH_KEY/#\~/$HOME}" ]]; then
        print_error "SSH key not found: $PI_SSH_KEY"
        exit 1
    fi
    
    # Test SSH connection
    print_step "Testing SSH connection to $PI_USER@$PI_HOST..."
    if ssh -i "${PI_SSH_KEY/#\~/$HOME}" -o ConnectTimeout=5 -o BatchMode=yes "$PI_USER@$PI_HOST" "echo 'SSH connection successful'" &> /dev/null; then
        print_success "SSH connection established"
    else
        print_error "Cannot connect to $PI_USER@$PI_HOST"
        echo "Please check your SSH key and Pi connectivity"
        exit 1
    fi
}

# Deploy using Ansible
deploy() {
    print_step "Starting deployment to $PI_HOST..."
    
    # Create temporary inventory
    TEMP_INVENTORY=$(mktemp)
    cat > "$TEMP_INVENTORY" << EOF
[raspberry_pi]
homeai-pi ansible_host=$PI_HOST ansible_user=$PI_USER ansible_ssh_private_key_file=${PI_SSH_KEY/#\~/$HOME}

[raspberry_pi:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

    # Run Ansible playbook with nice formatting
    export ANSIBLE_FORCE_COLOR=true
    
    if ansible-playbook \
        -i "$TEMP_INVENTORY" \
        ansible/playbooks/deploy.yml \
        --timeout=30 \
        -v; then
        print_success "Deployment completed successfully!"
    else
        print_error "Deployment failed!"
        rm -f "$TEMP_INVENTORY"
        exit 1
    fi
    
    # Clean up
    rm -f "$TEMP_INVENTORY"
}

# Show deployment summary
show_summary() {
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}${WHITE}                                  🧪 FLOWLAB DEPLOYMENT COMPLETE! 🧪                                 ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${WHITE}                              Your automation laboratory is ready!                                   ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${GREEN}🏠 Local Services:${NC}\n"
    echo -e "${CYAN}  📊 N8N Workflow Builder:    ${WHITE}http://$PI_HOST:${N8N_PORT:-5678}${NC}"
    echo -e "${CYAN}  🔍 SearxNG Search Engine:   ${WHITE}http://$PI_HOST:${SEARXNG_PORT:-8080}${NC} ${GREEN}(JSON API enabled)${NC}"
    echo -e "${CYAN}  📈 Freqtrade Market Data:   ${WHITE}http://$PI_HOST:${FREQTRADE_PORT:-8081}${NC} ${YELLOW}(optional)${NC}"
    echo -e "${CYAN}  🐳 Portainer Management:    ${WHITE}http://$PI_HOST:${PORTAINER_PORT:-9000}${NC}"
    
    echo -e "\n${BLUE}🚀 Ready-to-Use Workflows:${NC}"
    echo -e "${WHITE}  • Enhanced Crypto Scanner (uses CoinGecko API)${NC}"
    echo -e "${WHITE}  • News sentiment analysis via SearXNG${NC}"
    echo -e "${WHITE}  • Technical analysis with RSI, MACD, EMAs${NC}"
    echo -e "${WHITE}  • Telegram notifications ready${NC}"
    
    echo -e "\n${BLUE}🌐 Remote Access:${NC}"
    echo -e "${WHITE}  • Local network access only${NC}"
    echo -e "${WHITE}  • Set up port forwarding or VPN for remote access${NC}"
    
    echo -e "\n${YELLOW}📝 Recent Improvements:${NC}"
    echo -e "${WHITE}  • SearXNG JSON API properly configured${NC}"
    echo -e "${WHITE}  • Simplified architecture using CoinGecko${NC}"
    echo -e "${WHITE}  • Enhanced error handling and reliability${NC}"
    echo -e "${WHITE}  • All configuration files properly mounted${NC}"
    
    echo -e "\n${YELLOW}📋 Next Steps:${NC}"
    echo -e "${WHITE}  1. Import workflows from /workflows/n8n/ in N8N${NC}"
    echo -e "${WHITE}  2. Configure Telegram bot credentials${NC}"
    echo -e "${WHITE}  3. Test the Enhanced Crypto Scanner workflow${NC}"
    
    echo -e "\n${YELLOW}📝 Notes:${NC}"
    echo -e "${WHITE}  • All services start with clean configurations${NC}"
    echo -e "${WHITE}  • Services may take 2-3 minutes to fully start${NC}"
    echo -e "${WHITE}  • Check logs if any service needs troubleshooting: ./scripts/helpers/logs.sh${NC}"
    echo -e "${WHITE}  • Create your own passwords during first setup${NC}"
    echo -e "${WHITE}  • Data is persistent across deployments${NC}"
    echo -e "${WHITE}  • Automatic updates run daily at 2 AM${NC}"
    
    echo -e "\n${BLUE}🛠️  Management Commands:${NC}"
    echo -e "${WHITE}  • Update services:     ${CYAN}./scripts/update.sh${NC}"
    echo -e "${WHITE}  • View logs:           ${CYAN}./scripts/helpers/logs.sh${NC}"
    echo -e "${WHITE}  • Check status:        ${CYAN}ssh $PI_USER@$PI_HOST 'cd /opt/homeai && docker-compose ps'${NC}"
    
    echo -e "\n${GREEN}🧪 Welcome to your FlowLab! Start building amazing workflows! 🚀${NC}\n"
}

show_disclaimer() {
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC}${RED}                                    ⚠️  IMPORTANT DISCLAIMER ⚠️                                     ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${WHITE}📋 ${CYAN}PREREQUISITES:${NC}"
    echo -e "  ${GREEN}✓${NC} Raspberry Pi 4+ with Raspberry Pi OS and SSH enabled"
    echo -e "  ${GREEN}✓${NC} SSH key configured: ${CYAN}ssh $PI_USER@$PI_HOST${NC} works"
    echo -e "  ${GREEN}✓${NC} Ansible installed and network connectivity to Pi"
    echo -e "  ${GREEN}✓${NC} config.env file properly configured"
    
    echo -e "\n${PURPLE}🚀 ${WHITE}DEPLOYMENT OVERVIEW:${NC}"
    echo -e "  ${CYAN}•${NC} N8N Workflow Platform, SearXNG Search, PostgreSQL Database"
    echo -e "  ${CYAN}•${NC} Portainer Management, Freqtrade API (optional), Auto-updates"
    echo -e "  ${CYAN}•${NC} Ready-to-use crypto analysis and news sentiment workflows"
    
    echo -e "\n${YELLOW}⚠️  ${WHITE}IMPORTANT:${NC}"
    echo -e "  ${RED}•${NC} This will modify your Pi's system and install Docker"
    echo -e "  ${RED}•${NC} Process takes 10-15 minutes - ensure stable power/network"
    echo -e "  ${RED}•${NC} Services start with default passwords - configure after deployment"
    
    echo -e "\n${WHITE}📍 Target: ${YELLOW}$PI_USER@$PI_HOST${NC} | SSH Key: ${YELLOW}$PI_SSH_KEY${NC}"
    
    echo -e "\n${CYAN}Press ${WHITE}[ENTER]${CYAN} to start deployment or ${WHITE}[Ctrl+C]${CYAN} to cancel...${NC}"
    read -r
    
    echo -e "\n${GREEN}🚀 Starting FlowLab deployment...${NC}\n"
}

# Main execution
main() {
    print_header
    show_disclaimer
    check_prerequisites
    deploy
    show_summary
}

# Run main function
main "$@" 