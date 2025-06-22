#!/bin/bash

# =============================================================================
# FlowLab - Workflow Sync Script  
# =============================================================================
# Automatically syncs local workflow files to your FlowLab n8n instance

set -euo pipefail

# Load configuration
if [[ ! -f "config.env" ]]; then
    echo "❌ config.env file not found!"
    exit 1
fi

source config.env

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m'

# N8N Configuration
N8N_URL="http://${PI_HOST}:${N8N_PORT:-5678}"
WORKFLOW_DIR="workflows/n8n"

print_header() {
    echo -e "\n${CYAN}🧪 FlowLab - Workflow Sync${NC}"
    echo -e "${WHITE}================================${NC}\n"
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

check_n8n_connection() {
    print_step "Checking n8n connection..."
    
    if curl -s -f "$N8N_URL/healthz" > /dev/null 2>&1; then
        print_success "Connected to n8n at $N8N_URL"
        return 0
    else
        print_error "Cannot connect to n8n at $N8N_URL"
        echo "Make sure n8n is running and accessible"
        return 1
    fi
}

sync_workflow() {
    local workflow_file="$1"
    local workflow_name=$(basename "$workflow_file" .json)
    
    print_step "Syncing workflow: $workflow_name"
    
    # Check if workflow already exists
    existing_id=$(curl -s "$N8N_URL/api/v1/workflows" | \
        jq -r ".data[] | select(.name == \"$workflow_name\") | .id" 2>/dev/null || echo "")
    
    if [[ -n "$existing_id" && "$existing_id" != "null" ]]; then
        # Update existing workflow
        print_step "Updating existing workflow (ID: $existing_id)"
        
        response=$(curl -s -X PUT "$N8N_URL/api/v1/workflows/$existing_id" \
            -H "Content-Type: application/json" \
            -d @"$workflow_file" || echo "ERROR")
            
        if [[ "$response" != "ERROR" ]]; then
            print_success "Updated workflow: $workflow_name"
        else
            print_error "Failed to update workflow: $workflow_name"
        fi
    else
        # Create new workflow
        print_step "Creating new workflow"
        
        response=$(curl -s -X POST "$N8N_URL/api/v1/workflows" \
            -H "Content-Type: application/json" \
            -d @"$workflow_file" || echo "ERROR")
            
        if [[ "$response" != "ERROR" ]]; then
            print_success "Created workflow: $workflow_name"
        else
            print_error "Failed to create workflow: $workflow_name"
        fi
    fi
}

export_workflows() {
    print_step "Exporting current workflows from n8n..."
    
    # Create backup directory with timestamp
    backup_dir="workflows/backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Get all workflows
    workflows=$(curl -s "$N8N_URL/api/v1/workflows" | jq -r '.data[] | @base64')
    
    if [[ -z "$workflows" ]]; then
        print_warning "No workflows found in n8n"
        return
    fi
    
    for workflow in $workflows; do
        workflow_data=$(echo "$workflow" | base64 --decode)
        workflow_id=$(echo "$workflow_data" | jq -r '.id')
        workflow_name=$(echo "$workflow_data" | jq -r '.name')
        
        # Clean filename
        clean_name=$(echo "$workflow_name" | sed 's/[^a-zA-Z0-9_-]/_/g')
        
        # Export full workflow
        curl -s "$N8N_URL/api/v1/workflows/$workflow_id" | \
            jq '.' > "$backup_dir/${clean_name}.json"
            
        print_success "Exported: $workflow_name"
    done
    
    print_success "Workflows backed up to: $backup_dir"
}

import_workflows() {
    print_step "Importing workflows from $WORKFLOW_DIR..."
    
    if [[ ! -d "$WORKFLOW_DIR" ]]; then
        print_error "Workflow directory not found: $WORKFLOW_DIR"
        return 1
    fi
    
    local count=0
    for workflow_file in "$WORKFLOW_DIR"/*.json; do
        if [[ -f "$workflow_file" ]]; then
            sync_workflow "$workflow_file"
            ((count++))
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        print_warning "No workflow files found in $WORKFLOW_DIR"
    else
        print_success "Processed $count workflow(s)"
    fi
}

watch_and_sync() {
    print_step "Starting workflow watch mode..."
    print_warning "Press Ctrl+C to stop watching"
    
    while true; do
        sleep 5
        
        # Check for file changes (basic implementation)
        for workflow_file in "$WORKFLOW_DIR"/*.json; do
            if [[ -f "$workflow_file" ]]; then
                # Check if file was modified in last 10 seconds
                if [[ $(find "$workflow_file" -mtime -10s 2>/dev/null) ]]; then
                    echo -e "\n${YELLOW}File changed: $(basename "$workflow_file")${NC}"
                    sync_workflow "$workflow_file"
                fi
            fi
        done
    done
}

show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  import    - Import local workflows to n8n (default)"
    echo "  export    - Export n8n workflows to local backup"
    echo "  watch     - Watch for local changes and auto-sync"
    echo "  help      - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0              # Import all workflows from $WORKFLOW_DIR"
    echo "  $0 export       # Backup current n8n workflows"
    echo "  $0 watch        # Auto-sync when files change"
}

main() {
    print_header
    
    command="${1:-import}"
    
    case "$command" in
        "import")
            check_n8n_connection && import_workflows
            ;;
        "export")
            check_n8n_connection && export_workflows
            ;;
        "watch")
            check_n8n_connection && watch_and_sync
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@" 