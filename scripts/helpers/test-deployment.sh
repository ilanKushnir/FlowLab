#!/bin/bash

# =============================================================================
# FlowLab - Deployment Validation Test
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
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

print_header() {
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  🧪 DEPLOYMENT VALIDATION TEST${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_test() {
    echo -e "${CYAN}🧪 Testing: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
}

print_fail() {
    echo -e "${RED}❌ FAIL: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

# Test functions
test_ssh_connection() {
    print_test "SSH connectivity to $PI_HOST"
    if ssh -i "${PI_SSH_KEY/#\~/$HOME}" -o ConnectTimeout=5 -o BatchMode=yes "$PI_USER@$PI_HOST" "echo 'connected'" &> /dev/null; then
        print_pass "SSH connection established"
        return 0
    else
        print_fail "Cannot connect via SSH"
        return 1
    fi
}

test_service_status() {
    print_test "Service status check"
    local services
    services=$(ssh -i "${PI_SSH_KEY/#\~/$HOME}" "$PI_USER@$PI_HOST" "cd /opt/homeai && sudo docker-compose ps --format json 2>/dev/null | jq -r '.[] | select(.State == \"Up\") | .Name' || echo 'error'")
    
    if [[ "$services" == "error" ]]; then
        print_fail "Unable to check service status"
        return 1
    fi
    
    # Expected services
    local expected=("n8n" "portainer" "postgres" "freqtrade" "searxng" "watchtower")
    local running_count=0
    
    echo -e "${BLUE}  Running services:${NC}"
    while IFS= read -r service; do
        [[ -n "$service" ]] && echo -e "    • $service" && ((running_count++))
    done <<< "$services"
    
    if [[ $running_count -ge 4 ]]; then
        print_pass "Core services running ($running_count/6)"
        return 0
    else
        print_warning "Only $running_count services running"
        return 1
    fi
}

test_freqtrade_config() {
    print_test "Freqtrade configuration validation"
    
    # Check if freqtrade config is properly mounted as file, not directory
    local config_check
    config_check=$(ssh -i "${PI_SSH_KEY/#\~/$HOME}" "$PI_USER@$PI_HOST" "cd /opt/homeai && sudo docker run --rm -v homeai_freqtrade_data:/freqtrade/user_data busybox file /freqtrade/user_data/config.json 2>/dev/null | grep -c 'JSON' || echo '0'")
    
    if [[ "$config_check" -gt 0 ]]; then
        print_pass "Freqtrade config.json is valid JSON file"
    else
        print_fail "Freqtrade config.json is not a valid file"
        return 1
    fi
    
    # Test freqtrade API response
    local api_response
    api_response=$(ssh -i "${PI_SSH_KEY/#\~/$HOME}" "$PI_USER@$PI_HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8081/api/v1/status || echo '000'")
    
    if [[ "$api_response" == "401" ]]; then
        print_pass "Freqtrade API responding (authentication required)"
        return 0
    elif [[ "$api_response" == "200" ]]; then
        print_pass "Freqtrade API responding"
        return 0
    else
        print_fail "Freqtrade API not responding (HTTP $api_response)"
        return 1
    fi
}

test_searxng_functionality() {
    print_test "SearxNG search functionality"
    
    local search_response
    search_response=$(ssh -i "${PI_SSH_KEY/#\~/$HOME}" "$PI_USER@$PI_HOST" "curl -s -o /dev/null -w '%{http_code}' 'http://localhost:8080/search?q=test&format=json' || echo '000'")
    
    if [[ "$search_response" == "200" ]]; then
        print_pass "SearxNG JSON API responding"
        return 0
    else
        print_fail "SearxNG not responding properly (HTTP $search_response)"
        return 1
    fi
}

test_n8n_accessibility() {
    print_test "N8N web interface"
    
    local n8n_response
    n8n_response=$(ssh -i "${PI_SSH_KEY/#\~/$HOME}" "$PI_USER@$PI_HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost:5678 || echo '000'")
    
    if [[ "$n8n_response" == "200" ]]; then
        print_pass "N8N web interface accessible"
        return 0
    else
        print_fail "N8N not accessible (HTTP $n8n_response)"
        return 1
    fi
}

test_volume_initialization() {
    print_test "Docker volume initialization"
    
    # Check if volumes exist and are properly initialized
    local volumes
    volumes=$(ssh -i "${PI_SSH_KEY/#\~/$HOME}" "$PI_USER@$PI_HOST" "sudo docker volume ls | grep -c homeai || echo '0'")
    
    if [[ "$volumes" -gt 0 ]]; then
        print_pass "Docker volumes created ($volumes volumes)"
        return 0
    else
        print_fail "Docker volumes not found"
        return 1
    fi
}

test_file_mount_issues() {
    print_test "File mount issue prevention"
    
    # Check that service files are actual files, not directories
    local file_checks=0
    
    # Check freqtrade config
    local ft_config
    ft_config=$(ssh -i "${PI_SSH_KEY/#\~/$HOME}" "$PI_USER@$PI_HOST" "cd /opt/homeai && sudo docker run --rm -v homeai_freqtrade_data:/freqtrade/user_data busybox test -f /freqtrade/user_data/config.json && echo 'file' || echo 'not-file'")
    
    if [[ "$ft_config" == "file" ]]; then
        ((file_checks++))
    fi
    
    if [[ $file_checks -gt 0 ]]; then
        print_pass "Configuration files properly mounted as files"
        return 0
    else
        print_fail "Configuration files have mount issues"
        return 1
    fi
}

# Main test execution
main() {
    print_header
    
    local tests=0
    local passed=0
    local failed=0
    
    # Run tests
    for test in test_ssh_connection test_service_status test_freqtrade_config test_searxng_functionality test_n8n_accessibility test_volume_initialization test_file_mount_issues; do
        ((tests++))
        if $test; then
            ((passed++))
        else
            ((failed++))
        fi
        echo
    done
    
    # Summary
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  📊 TEST RESULTS${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${GREEN}✅ Passed: $passed${NC}"
    echo -e "${RED}❌ Failed: $failed${NC}"
    echo -e "${BLUE}📝 Total:  $tests${NC}\n"
    
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed! Deployment is working correctly.${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Some tests failed. Check the logs for details:${NC}"
        echo -e "${WHITE}   ./scripts/helpers/logs.sh${NC}"
        return 1
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 