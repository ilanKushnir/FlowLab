#!/bin/bash

# =============================================================================
# FlowLab - Update Script
# =============================================================================

set -euo pipefail

# Load configuration
if [[ ! -f "config.env" ]]; then
    echo "❌ config.env file not found!"
    exit 1
fi

source config.env

# Color codes
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Add timeout to SSH commands to prevent hanging
SSH_TIMEOUT=30

main() {
    echo -e "\n${WHITE}🧪 Updating FlowLab - Your Automation Laboratory...${NC}\n"
    
    print_step "Copying configuration files..."
    scp -o ConnectTimeout=10 config.env "$PI_USER@$PI_HOST:/tmp/"
    scp -o ConnectTimeout=10 docker/docker-compose.yml "$PI_USER@$PI_HOST:/tmp/"
    
    print_step "Copying service configurations..."
    scp -o ConnectTimeout=10 -r docker/services "$PI_USER@$PI_HOST:/tmp/"
    scp -o ConnectTimeout=10 -r workflows "$PI_USER@$PI_HOST:/tmp/"
    
    print_step "Stopping services..."
    ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 "$PI_USER@$PI_HOST" \
        "cd /opt/homeai && sudo docker-compose down --timeout 10 || true"
    
    print_step "Updating configuration files..."
    ssh -o ConnectTimeout=10 "$PI_USER@$PI_HOST" "
        sudo mv /tmp/config.env /opt/homeai/
        sudo mv /tmp/docker-compose.yml /opt/homeai/
    "
    
    print_step "Updating service directories..."
    ssh -o ConnectTimeout=10 "$PI_USER@$PI_HOST" "
        sudo rm -rf /opt/homeai/services
        sudo rm -rf /opt/homeai/workflows
        sudo mv /tmp/services /opt/homeai/
        sudo mv /tmp/workflows /opt/homeai/
        sudo chown -R homeai:homeai /opt/homeai/
    "
    
    print_step "Cleaning up old containers..."
    ssh -o ConnectTimeout=10 "$PI_USER@$PI_HOST" "
        sudo docker rm -f cloudflared 2>/dev/null || true
        sudo docker rmi cloudflare/cloudflared:latest 2>/dev/null || true
    " || true
    
    print_step "Starting services (this runs in background)..."
    # Start services in background to avoid hanging
    ssh -o ConnectTimeout=10 "$PI_USER@$PI_HOST" \
        "cd /opt/homeai && nohup sudo -u homeai docker-compose up -d > /tmp/docker-start.log 2>&1 &" || true
    
    print_success "Update completed!"
    print_info "Services are starting in the background..."
    print_info "Check status in 1-2 minutes with:"
    echo -e "${WHITE}  ssh $PI_USER@$PI_HOST 'cd /opt/homeai && docker-compose ps'${NC}"
    echo -e "${WHITE}  Or check logs with: ./scripts/helpers/logs.sh${NC}\n"
}

main "$@" 