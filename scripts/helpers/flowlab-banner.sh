#!/bin/bash

# =============================================================================
# FlowLab - Banner & Branding
# =============================================================================

# Colors
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
GREEN='\033[0;32m'
NC='\033[0m'

# Simple FlowLab banner
show_flowlab_banner() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}${CYAN}    ███████╗██╗      ██████╗ ██╗    ██╗██╗      █████╗ ██████╗                                 ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${CYAN}    ██╔════╝██║     ██╔═══██╗██║    ██║██║     ██╔══██╗██╔══██╗                                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${CYAN}    █████╗  ██║     ██║   ██║██║ █╗ ██║██║     ███████║██████╔╝                                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${CYAN}    ██╔══╝  ██║     ██║   ██║██║███╗██║██║     ██╔══██║██╔══██╗                                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${CYAN}    ██║     ███████╗╚██████╔╝╚███╔███╔╝███████╗██║  ██║██████╔╝                                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${CYAN}    ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═════╝                                 ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${WHITE}                                                                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${WHITE}                    🧪 Your Personal Automation Laboratory 🧪                                   ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}${WHITE}                         Where workflows come to life!                                          ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Compact FlowLab header
show_flowlab_header() {
    echo -e "\n${CYAN}🧪 FlowLab${NC} ${WHITE}- Your Personal Automation Laboratory${NC}\n"
}

# Success message with FlowLab branding
show_flowlab_success() {
    echo -e "\n${GREEN}🧪 Welcome to your FlowLab! Start building amazing workflows! 🚀${NC}\n"
} 