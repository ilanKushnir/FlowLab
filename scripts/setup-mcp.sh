#!/bin/bash

# FlowLab MCP Server Setup Script
# This script installs and configures MCP servers for local development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${WHITE}                                  🤖 FlowLab MCP Setup 🤖                                       ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Node.js is installed
check_nodejs() {
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js 18+ first."
        exit 1
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js version 18+ is required. Current version: $(node --version)"
        exit 1
    fi
    
    print_success "Node.js $(node --version) detected"
}

# Install MCP servers globally
install_mcp_servers() {
    print_info "Installing MCP servers globally..."
    
    # Core MCP servers
    npm install -g @nerding-io/n8n-nodes-mcp
    print_success "Installed n8n-nodes-mcp"
    
    npm install -g @modelcontextprotocol/server-brave-search
    print_success "Installed Brave Search MCP server"
    
    npm install -g @modelcontextprotocol/server-weather
    print_success "Installed Weather MCP server"
    
    npm install -g @modelcontextprotocol/server-web-search
    print_success "Installed Web Search MCP server"
    
    # Optional servers
    if command -v npm list -g @modelcontextprotocol/server-openai &> /dev/null; then
        print_info "OpenAI MCP server already installed"
    else
        npm install -g @modelcontextprotocol/server-openai
        print_success "Installed OpenAI MCP server"
    fi
    
    if command -v npm list -g @modelcontextprotocol/server-serper &> /dev/null; then
        print_info "Serper MCP server already installed"
    else
        npm install -g @modelcontextprotocol/server-serper
        print_success "Installed Serper MCP server"
    fi
}

# Setup environment file
setup_environment() {
    if [ ! -f "mcp/.env" ]; then
        print_info "Creating mcp/.env from template..."
        cp mcp/mcp.env.example mcp/.env
        print_warning "Please edit mcp/.env with your actual API keys and credentials"
    else
        print_info "mcp/.env already exists"
    fi
}

# Test MCP server installation
test_mcp_servers() {
    print_info "Testing MCP server installations..."
    
    # Test if servers can be executed
    if npx @nerding-io/n8n-nodes-mcp --help &> /dev/null; then
        print_success "n8n-nodes-mcp server is working"
    else
        print_warning "n8n-nodes-mcp server test failed"
    fi
    
    if npx @modelcontextprotocol/server-brave-search --help &> /dev/null; then
        print_success "Brave Search MCP server is working"
    else
        print_warning "Brave Search MCP server test failed"
    fi
}

# Main execution
main() {
    print_header
    
    print_info "Setting up MCP servers for FlowLab development..."
    echo
    
    check_nodejs
    install_mcp_servers
    setup_environment
    test_mcp_servers
    
    echo
    print_success "MCP setup completed!"
    echo
    print_info "Next steps:"
    echo -e "  ${CYAN}1.${NC} Edit ${YELLOW}mcp/.env${NC} with your API keys"
    echo -e "  ${CYAN}2.${NC} Configure Cursor MCP settings (see mcp/README.md)"
    echo -e "  ${CYAN}3.${NC} Start using MCP in your N8N workflows"
    echo
    print_info "Available MCP servers:"
    echo -e "  ${GREEN}•${NC} flowlab-n8n - Direct N8N workflow management"
    echo -e "  ${GREEN}•${NC} brave-search - Web search capabilities"
    echo -e "  ${GREEN}•${NC} searxng-local - Local SearXNG integration"
    echo -e "  ${GREEN}•${NC} weather - Weather data access"
    echo -e "  ${GREEN}•${NC} crypto-data - Cryptocurrency market data"
    echo
}

main "$@" 