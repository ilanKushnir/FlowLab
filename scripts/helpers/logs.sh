#!/bin/bash

# =============================================================================
# FlowLab - Logs Script
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
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

print_header() {
    echo -e "\n${WHITE}📋 FlowLab - Service Logs${NC}\n"
}

show_service_logs() {
    local service=$1
    echo -e "${CYAN}▶ $service logs:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    ssh "$PI_USER@$PI_HOST" "cd /opt/homeai && sudo docker-compose logs --tail=20 $service" || echo "❌ Failed to get logs for $service"
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

main() {
    print_header
    
    # Check if specific service requested
    if [[ $# -gt 0 ]]; then
        show_service_logs "$1"
        exit 0
    fi
    
    # Show all services
    echo -e "${GREEN}🐳 Container Status:${NC}"
    ssh "$PI_USER@$PI_HOST" "cd /opt/homeai && sudo docker-compose ps" || echo "❌ Failed to get container status"
    echo
    
    # Show logs for each service
    local services=("n8n" "searxng" "freqtrade" "portainer" "postgres" "watchtower")
    

    
    for service in "${services[@]}"; do
        show_service_logs "$service"
    done
    
    echo -e "${WHITE}💡 Management Commands:${NC}"
    echo -e "${WHITE}   • './scripts/helpers/logs.sh <service_name>' - View specific service logs${NC}"
    echo -e "${WHITE}   • './scripts/helpers/test-deployment.sh' - Validate deployment${NC}"
    echo -e "${WHITE}   • './scripts/update.sh' - Push local changes${NC}"
    
    local available_services="n8n, searxng, freqtrade, portainer, postgres, watchtower"
    echo -e "${WHITE}💡 Available services: $available_services${NC}\n"
}

main "$@" 