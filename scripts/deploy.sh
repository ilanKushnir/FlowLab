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
    echo -e "${CYAN}  🔍 SearxNG Search Engine:   ${WHITE}http://$PI_HOST:${SEARXNG_PORT:-8080}${NC}"
    echo -e "${CYAN}  📈 Freqtrade Market Data:   ${WHITE}http://$PI_HOST:${FREQTRADE_PORT:-8081}${NC}"
    echo -e "${CYAN}  🐳 Portainer Management:    ${WHITE}http://$PI_HOST:${PORTAINER_PORT:-9000}${NC}"
    
    echo -e "\n${BLUE}🌐 Remote Access:${NC}"
    echo -e "${WHITE}  • Local network access only${NC}"
    echo -e "${WHITE}  • Set up port forwarding or VPN for remote access${NC}"
    
    echo -e "\n${YELLOW}📝 Notes:${NC}"
    echo -e "${WHITE}  • All services start with clean configurations${NC}"
    echo -e "${WHITE}  • Deployment process has been improved for reliability${NC}"
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

# Main execution
main() {
    print_header
    check_prerequisites
    deploy
    show_summary
}

# Run main function
main "$@" 