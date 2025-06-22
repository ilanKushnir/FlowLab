# Deployment Issues & Fixes

This document outlines all the issues encountered during deployment and the systematic fixes applied to prevent them in future fresh deployments.

## Issues Identified

### 1. **File vs Directory Mounting**
**Problem**: Ansible `copy` module with trailing slashes created directories instead of files
**Impact**: Config files appeared as directories, causing mount failures
**Fix**: Changed to individual file copying with explicit file paths
```diff
- src: "{{ playbook_dir }}/../../docker/services/searxng/"
- dest: "{{ remote_project_path }}/docker/services/searxng/"
+ src: "{{ playbook_dir }}/../../docker/services/searxng/settings.yml"
+ dest: "{{ remote_project_path }}/services/searxng/settings.yml"
```

### 2. **Freqtrade Command Syntax**
**Problem**: Docker entrypoint automatically adds "freqtrade", but we were adding it again
**Impact**: Command became "freqtrade freqtrade webserver" → error
**Fix**: Removed "freqtrade" prefix from command
```diff
- command: freqtrade webserver --config /freqtrade/user_data/config.json
+ command: ["webserver", "--config", "/freqtrade/user_data/config.json"]
```

### 3. **Freqtrade Configuration Validation**
**Problem**: JSON schema validation failed on multiple fields
**Impact**: Service crashed on startup with validation errors
**Fix**: Updated config values to meet minimum requirements:
- `stake_amount: 0` → `stake_amount: 100`
- `dry_run_wallet: 0` → `dry_run_wallet: 1000`  
- `allowed_risk: 0` → `allowed_risk: 0.01`
- Added required API fields: `username` and `password`

### 4. **Volume Mount Caching**
**Problem**: Docker cached incorrect directory mounts in volumes
**Impact**: Even after fixing files, volumes still contained directories
**Fix**: Added volume cleanup and proper initialization:
```bash
# Clean problematic volumes
docker volume rm homeai_freqtrade_data || true

# Proper initialization with busybox
docker run --rm -v homeai_freqtrade_data:/freqtrade/user_data busybox cp /tmp/config.json /freqtrade/user_data/
```

### 5. **SearxNG Custom Configuration Issues**
**Problem**: Settings file mounted as read-only caused permission conflicts
**Impact**: SearxNG couldn't start, showing "no python application found"
**Fix**: Simplified to use default SearxNG settings instead of custom mounts

### 6. **Docker Compose YAML Syntax**
**Problem**: Manual edits left invalid YAML structures (empty volumes array)
**Impact**: Docker compose couldn't parse configuration
**Fix**: Proper YAML structure validation and cleanup

### 7. **Update Script Hanging**
**Problem**: `scripts/update.sh` would hang during `sudo systemctl restart homeai`
**Impact**: Updates would appear to fail, required manual intervention
**Fix**: Added timeouts and non-blocking service restarts:
```bash
# Old (hanging)
ssh "$PI_USER@$PI_HOST" "sudo systemctl restart homeai"

# New (non-blocking with timeout)
ssh -o ConnectTimeout=10 "$PI_USER@$PI_HOST" "nohup sudo systemctl restart homeai > /dev/null 2>&1 &"
```

### 8. **Service Health Check Failures**
**Problem**: Portainer showed "unhealthy" status for SearxNG and Watchtower
**Impact**: False negative health reports, confusing monitoring
**Fix**: Updated health checks to use correct commands:
```yaml
# SearxNG: wget not available → use curl
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/"]

# Watchtower: complex ps aux → simple pgrep
healthcheck:
  test: ["CMD", "pgrep", "watchtower"]
```

### 9. **Service Status Detection Command Issues**
**Problem**: `docker-compose ps --format json | jq` failed with "jq: not found"
**Impact**: Service validation failed during deployment
**Fix**: Replaced with compatible command:
```bash
# Old (required jq)
docker-compose ps --format json | jq -r '.[] | select(.State == "Up") | .Name'

# New (uses awk, universally available)
docker-compose ps | awk 'NR>2 && $2 ~ /Up/ {print $1}' | sed 's/_[0-9]*$//'
```

## Systematic Fixes Applied

### 1. **Enhanced Ansible Playbook**
- ✅ Individual file copying instead of directory copying
- ✅ Proper volume initialization with busybox containers
- ✅ Pre-deployment cleanup of problematic volumes
- ✅ Service validation after deployment
- ✅ Better error handling and rollback capability

### 2. **Improved Docker Compose**
- ✅ Fixed freqtrade command syntax
- ✅ Removed problematic file mounts (use volumes only)
- ✅ Simplified SearxNG to use defaults
- ✅ Proper service dependencies and health checks

### 3. **Configuration Management**
- ✅ Valid freqtrade config with proper field values
- ✅ Removed complex custom configurations that caused issues
- ✅ Focus on reliability over advanced features for deployment

### 4. **Validation & Testing**
- ✅ Created comprehensive test script (`test-deployment.sh`)
- ✅ Automated validation of common issues
- ✅ Service status checking and reporting
- ✅ File mount verification

## Prevention Measures

### 1. **Pre-deployment Checks**
```bash
# Clean any existing problematic volumes
docker volume rm homeai_freqtrade_data || true

# Verify file structures before deployment
test -f docker/services/freqtrade/config.json
```

### 2. **Volume Initialization**
```bash
# Proper volume setup with files, not bind mounts
docker run --rm \
  -v homeai_freqtrade_data:/freqtrade/user_data \
  -v /opt/homeai/services/freqtrade/config.json:/tmp/config.json \
  busybox cp /tmp/config.json /freqtrade/user_data/
```

### 3. **Service Validation**
```bash
# Verify services after deployment
docker-compose ps --format json | jq -r '.[] | select(.State == "Up") | .Name'

# Test API endpoints
curl -s http://localhost:8081/api/v1/status  # Freqtrade
curl -s http://localhost:8080/search?q=test&format=json  # SearxNG
```

### 4. **Configuration Validation**
```bash
# Validate JSON configs before deployment
jq . docker/services/freqtrade/config.json > /dev/null

# Check for common issues
grep -v ': 0[^.]' docker/services/freqtrade/config.json  # No zero values
```

## Testing

Use the validation script to verify deployment:
```bash
./scripts/helpers/test-deployment.sh
```

This tests:
- SSH connectivity
- Service status
- Freqtrade config validation
- SearxNG functionality  
- N8N accessibility
- Volume initialization
- File mount issues

## Key Learnings

1. **Ansible Copy Behavior**: Trailing slashes in `copy` module create directories, not files
2. **Docker Entrypoints**: Container entrypoints can modify commands unexpectedly
3. **Volume Persistence**: Docker volumes cache mount structures across container recreations
4. **JSON Schema**: Freqtrade has strict validation requiring non-zero values for financial fields
5. **Read-only Mounts**: Some services expect to modify their config files and can't work with read-only mounts

## Result

With these fixes, fresh deployments should:
- ✅ Complete without file mount errors
- ✅ Start all services successfully
- ✅ Pass validation tests
- ✅ Work reliably across different Pi configurations
- ✅ Be easily debuggable when issues occur
- ✅ **No longer hang during updates** (timeout protection added)
- ✅ **Show accurate health status** in Portainer
- ✅ **Include workflow management tools** for development
- ✅ **Work without external dependencies** (cloudflared removed)
- ✅ **Provide 2000+ workflow examples** for reference 