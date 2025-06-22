#!/bin/bash

# =============================================================================
# FlowLab Deployment Verification Script
# =============================================================================

set -euo pipefail

# Load configuration
if [[ ! -f "config.env" ]]; then
    echo "❌ config.env file not found!"
    exit 1
fi

source config.env

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${CYAN}🧪 FlowLab Deployment Verification${NC}\n"
}

test_service() {
    local service_name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    
    echo -n "Testing $service_name... "
    
    if curl -s -m 10 -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        return 1
    fi
}

test_searxng_json() {
    echo -n "Testing SearXNG JSON API... "
    
    local response=$(curl -s -m 10 "http://$PI_HOST:${SEARXNG_PORT:-8080}/search?q=test&format=json&pageno=1")
    
    if echo "$response" | jq -e '.results' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ JSON API working${NC}"
        return 0
    else
        echo -e "${RED}❌ JSON API not working${NC}"
        echo "Response: $response"
        return 1
    fi
}

test_coingecko_api() {
    echo -n "Testing CoinGecko API access... "
    
    local response=$(curl -s -m 10 "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=1&interval=hourly")
    
    if echo "$response" | jq -e '.prices' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ CoinGecko API accessible${NC}"
        return 0
    else
        echo -e "${RED}❌ CoinGecko API not accessible${NC}"
        return 1
    fi
}

main() {
    print_header
    
    local failed_tests=0
    
    # Test basic service availability
    test_service "N8N" "http://$PI_HOST:${N8N_PORT:-5678}/healthz" || ((failed_tests++))
    test_service "SearXNG" "http://$PI_HOST:${SEARXNG_PORT:-8080}/" || ((failed_tests++))
    test_service "Freqtrade" "http://$PI_HOST:${FREQTRADE_PORT:-8081}/api/v1/ping" || ((failed_tests++))
    test_service "Portainer" "http://$PI_HOST:${PORTAINER_PORT:-9000}/" || ((failed_tests++))
    
    # Test specific functionality
    test_searxng_json || ((failed_tests++))
    test_coingecko_api || ((failed_tests++))
    
    echo -e "\n${CYAN}📊 Summary:${NC}"
    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}✅ All tests passed! FlowLab is ready to use.${NC}"
        echo -e "\n${BLUE}🚀 Next steps:${NC}"
        echo -e "1. Access N8N at http://$PI_HOST:${N8N_PORT:-5678}"
        echo -e "2. Import the Enhanced Crypto Scanner workflow"
        echo -e "3. Configure your Telegram bot credentials"
    else
        echo -e "${RED}❌ $failed_tests test(s) failed.${NC}"
        echo -e "\n${YELLOW}🔧 Troubleshooting:${NC}"
        echo -e "• Check service logs: ./scripts/helpers/logs.sh [service_name]"
        echo -e "• Verify container status: ssh $PI_USER@$PI_HOST 'cd /opt/homeai && docker-compose ps'"
        echo -e "• Wait a few minutes for services to fully start"
        exit 1
    fi
}

main "$@" 