#!/bin/bash

# =============================================================================
# FlowLab - Workflow Sources Download Script
# =============================================================================
# Downloads workflow collections for local reference and Cursor context

set -euo pipefail

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_FILE="workflow-sources.yaml"
TEMP_DIR="/tmp/workflow-downloads"

print_header() {
    echo -e "\n${CYAN}📚 FlowLab - Workflow Sources Downloader${NC}"
    echo -e "${WHITE}==========================================${NC}\n"
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

check_dependencies() {
    print_step "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command -v yq &> /dev/null; then
        missing_deps+=("yq")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo "Install with:"
        echo "  macOS: brew install yq git curl"
        echo "  Ubuntu: sudo apt install yq git curl"
        return 1
    fi
    
    print_success "All dependencies available"
}

create_target_directory() {
    local target_dir="$1"
    
    if [[ -d "$target_dir" ]]; then
        print_warning "Target directory exists, cleaning up..."
        rm -rf "$target_dir"
    fi
    
    mkdir -p "$target_dir"
    print_success "Created target directory: $target_dir"
}

download_github_source() {
    local name="$1"
    local url="$2"
    local path="$3"
    local target_dir="$4"
    local organize_by_source="$5"
    
    print_step "Downloading $name..."
    
    # Extract repo info
    local repo_url="${url%.git}"
    local repo_name=$(basename "$repo_url")
    local repo_owner=$(basename "$(dirname "$repo_url")")
    
    # Create temporary clone directory
    local clone_dir="$TEMP_DIR/$name"
    mkdir -p "$clone_dir"
    
    # Clone repository
    print_info "Cloning $repo_owner/$repo_name..."
    git clone --depth 1 "$url.git" "$clone_dir" --quiet
    
    # Determine source directory
    local source_dir="$clone_dir"
    if [[ -n "$path" ]]; then
        source_dir="$clone_dir/$path"
    fi
    
    if [[ ! -d "$source_dir" ]]; then
        print_warning "Path not found: $path in $name"
        return 1
    fi
    
    # Determine target location
    local final_target_dir="$target_dir"
    if [[ "$organize_by_source" == "true" ]]; then
        final_target_dir="$target_dir/$name"
    fi
    
    mkdir -p "$final_target_dir"
    
    # Copy files matching patterns
    local copied_count=0
    
    # Copy JSON workflows
    while IFS= read -r -d '' file; do
        local relative_path="${file#$source_dir/}"
        local target_file="$final_target_dir/$relative_path"
        
        # Create target directory if needed
        mkdir -p "$(dirname "$target_file")"
        
        # Copy file
        cp "$file" "$target_file"
        ((copied_count++))
    done < <(find "$source_dir" -name "*.json" -type f -print0 2>/dev/null || true)
    
    # Copy README files
    while IFS= read -r -d '' file; do
        local relative_path="${file#$source_dir/}"
        local target_file="$final_target_dir/$relative_path"
        
        mkdir -p "$(dirname "$target_file")"
        cp "$file" "$target_file"
        ((copied_count++))
    done < <(find "$source_dir" -name "README*" -type f -print0 2>/dev/null || true)
    
    # Create source info file
    cat > "$final_target_dir/.source-info.md" << EOF
# Source Information

**Name**: $name
**URL**: $url
**Path**: $path
**Downloaded**: $(date)
**Files**: $copied_count

## Description
Source from $repo_owner/$repo_name repository.
EOF
    
    print_success "Downloaded $copied_count files from $name"
    
    # Cleanup
    rm -rf "$clone_dir"
}

download_all_sources() {
    print_step "Reading configuration from $CONFIG_FILE..."
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    # Read configuration
    local target_directory=$(yq e '.download.target_directory' "$CONFIG_FILE")
    local organize_by_source=$(yq e '.download.organize_by_source' "$CONFIG_FILE")
    
    # Create target directory
    create_target_directory "$target_directory"
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    
    # Get number of sources
    local source_count=$(yq e '.sources | length' "$CONFIG_FILE")
    print_info "Found $source_count workflow sources to download"
    
    # Download each source
    for ((i=0; i<source_count; i++)); do
        local name=$(yq e ".sources[$i].name" "$CONFIG_FILE")
        local description=$(yq e ".sources[$i].description" "$CONFIG_FILE")
        local type=$(yq e ".sources[$i].type" "$CONFIG_FILE")
        local url=$(yq e ".sources[$i].url" "$CONFIG_FILE")
        local path=$(yq e ".sources[$i].path" "$CONFIG_FILE")
        
        echo -e "\n${WHITE}📦 $name${NC}"
        echo -e "${WHITE}   $description${NC}"
        
        case "$type" in
            "github")
                download_github_source "$name" "$url" "$path" "$target_directory" "$organize_by_source"
                ;;
            *)
                print_warning "Unknown source type: $type"
                ;;
        esac
    done
    
    # Cleanup temp directory
    rm -rf "$TEMP_DIR"
    
    # Create index file
    create_index_file "$target_directory"
}

create_index_file() {
    local target_dir="$1"
    local index_file="$target_dir/INDEX.md"
    
    print_step "Creating index file..."
    
    cat > "$index_file" << 'EOF'
# Workflow References Index

This directory contains downloaded workflow collections for reference when building new n8n workflows.

## How to Use

1. **Browse workflows** in subdirectories for examples
2. **Search for patterns** using your editor's search
3. **Copy useful nodes/patterns** into your workflows
4. **Learn from community best practices**

## Structure

EOF
    
    # Add directory listing
    if [[ -d "$target_dir" ]]; then
        for dir in "$target_dir"/*; do
            if [[ -d "$dir" ]]; then
                local dir_name=$(basename "$dir")
                echo "- **$dir_name/** - " >> "$index_file"
                
                # Add description from source info if available
                if [[ -f "$dir/.source-info.md" ]]; then
                    local description=$(grep "^**URL**:" "$dir/.source-info.md" | sed 's/\*\*URL\*\*: //')
                    local file_count=$(grep "^**Files**:" "$dir/.source-info.md" | sed 's/\*\*Files\*\*: //')
                    echo "  - Source: $description" >> "$index_file"
                    echo "  - Files: $file_count" >> "$index_file"
                fi
                echo "" >> "$index_file"
            fi
        done
    fi
    
    cat >> "$index_file" << 'EOF'

## Adding New Sources

Edit `workflow-sources.yaml` and run this script again to download new sources.

## Last Updated

EOF
    echo "$(date)" >> "$index_file"
    
    print_success "Created index file: $index_file"
}

show_summary() {
    local target_directory=$(yq e '.download.target_directory' "$CONFIG_FILE")
    
    echo -e "\n${GREEN}🎉 Download completed!${NC}\n"
    
    echo -e "${WHITE}📁 Workflows downloaded to: ${CYAN}$target_directory${NC}"
    echo -e "${WHITE}📄 Browse index file: ${CYAN}$target_directory/INDEX.md${NC}"
    
    # Count total files
    local total_workflows=$(find "$target_directory" -name "*.json" -type f | wc -l)
    echo -e "${WHITE}📊 Total workflow files: ${CYAN}$total_workflows${NC}"
    
    echo -e "\n${BLUE}💡 Usage Tips:${NC}"
    echo -e "${WHITE}• Open the workflow-references folder in Cursor for context${NC}"
    echo -e "${WHITE}• Search across all files to find workflow patterns${NC}"
    echo -e "${WHITE}• Copy useful node configurations to your workflows${NC}"
    echo -e "${WHITE}• Re-run this script to update references${NC}\n"
}

main() {
    print_header
    
    case "${1:-download}" in
        "download"|"")
            check_dependencies && download_all_sources && show_summary
            ;;
        "clean")
            local target_directory=$(yq e '.download.target_directory' "$CONFIG_FILE" 2>/dev/null || echo "workflow-references")
            if [[ -d "$target_directory" ]]; then
                rm -rf "$target_directory"
                print_success "Cleaned target directory: $target_directory"
            else
                print_info "Target directory doesn't exist: $target_directory"
            fi
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  download  - Download all workflow sources (default)"
            echo "  clean     - Remove downloaded references"
            echo "  help      - Show this help"
            ;;
        *)
            print_error "Unknown command: $1"
            exit 1
            ;;
    esac
}

main "$@" 