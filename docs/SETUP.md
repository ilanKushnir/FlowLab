# 🛠️ FlowLab Development Setup Guide

> **For contributors and developers who want to modify FlowLab**

If you just want to deploy the system, see the main [README.md](../README.md) for simple installation.

## 🎯 Development Environment

### **Prerequisites**
- **Development Machine**: Mac/Linux/WSL2 with Docker
- **Target Pi**: Raspberry Pi 4 (4GB+ RAM) with SSH enabled
- **Tools**: Ansible, Docker, Git, SSH keys

### **Quick Development Setup**
```bash
# Clone and setup
git clone https://github.com/your-username/flowlab.git
cd flowlab

# Copy template and configure for your Pi
cp config.env.example config.env
nano config.env  # Set PI_HOST, PI_USER, PI_SSH_KEY

# Install Ansible (if not installed)
# macOS
brew install ansible

# Ubuntu/Debian
sudo apt update && sudo apt install ansible

# Verify connectivity
ssh $PI_USER@$PI_HOST "echo 'Connected to Pi'"
```

## 🔧 Development Workflow

### **1. Local Testing**
```bash
# Test Docker Compose locally (optional)
cd docker
docker-compose up --build

# Test specific services
docker-compose up n8n postgres  # Just N8N stack
docker-compose up searxng        # Just search engine
```

### **2. Deploy to Pi**
```bash
# Full deployment
./scripts/deploy.sh

# Quick updates (faster after initial deployment)
./scripts/update.sh

# Check logs
./scripts/helpers/logs.sh
./scripts/helpers/logs.sh n8n    # Specific service
```

### **3. Making Changes**

#### **Service Configuration**
```bash
# Edit service configs
nano docker/services/searxng/settings.yml    # SearxNG engines
nano docker/services/freqtrade/config.json   # Freqtrade exchanges

# Test changes
./scripts/update.sh
```

#### **Docker Compose Changes**
```bash
# Edit main compose file
nano docker/docker-compose.yml

# Deploy changes
./scripts/update.sh
```

#### **Ansible Playbook Changes**
```bash
# Edit deployment automation
nano ansible/playbooks/deploy.yml
nano ansible/templates/homeai.service.j2

# Test deployment
./scripts/deploy.sh
```

## 📁 Project Structure (Development View)

```
flowlab/
├── 📋 Configuration
│   ├── config.env.example       # Template for users
│   └── config.env               # Your local config (gitignored)
│
├── 🐳 Docker Services
│   ├── docker-compose.yml       # Main service definitions
│   └── services/
│       ├── searxng/
│       │   ├── settings.yml     # Search engine config
│       │   └── limiter.toml     # Rate limiting
│       └── freqtrade/
│           └── config.json      # Market data config
│
├── 🚀 Deployment
│   ├── ansible/
│   │   ├── playbooks/
│   │   │   └── deploy.yml       # Main deployment playbook
│   │   └── templates/
│   │       └── homeai.service.j2 # Systemd service template
│   └── scripts/
│       ├── deploy.sh            # Full deployment
│       ├── update.sh            # Quick updates (no longer hangs!)
│       ├── sync-workflows.sh    # Workflow sync with n8n
│       ├── download-workflow-sources.sh # Download workflow references
│       └── helpers/             # Utility scripts
│           ├── logs.sh          # Log viewer
│           ├── test-deployment.sh # Deployment validation
│           └── flowlab-banner.sh # FlowLab branding utilities
│
├── 🔄 Workflows & Examples
│   ├── workflows/
│   │   ├── n8n/                 # Your workflow templates
│   │   └── backup/              # Exported workflow backups
│   └── workflow-references/      # Downloaded community workflows
│
└── 📚 Documentation
    ├── README.md                # User guide (in project root)
├── docs/
│   ├── SETUP.md             # This file (dev setup)
│   ├── WORKFLOW_REFERENCES.md # Workflow reference docs
│   └── DEPLOYMENT_FIXES.md  # Common deployment fixes
    └── LICENSE                  # MIT license
```

## 🧪 Testing & Validation

### **Service Health Checks**
```bash
# Quick health check of all services
ssh $PI_USER@$PI_HOST "cd /opt/homeai && docker-compose ps"

# Detailed status
ssh $PI_USER@$PI_HOST "sudo systemctl status homeai"

# Individual service tests
curl http://$PI_HOST:5678/healthz     # N8N health
curl http://$PI_HOST:8080/search?q=test&format=json  # SearxNG
curl http://$PI_HOST:8081/api/v1/status  # Freqtrade
curl http://$PI_HOST:9000/           # Portainer
```

### **Log Analysis**
```bash
# View all logs
./scripts/helpers/logs.sh

# Follow specific service logs
./scripts/helpers/logs.sh n8n --follow

# Container level debugging
ssh $PI_USER@$PI_HOST "cd /opt/homeai && docker-compose logs searxng"
```

### **Performance Testing**
```bash
# SearxNG search performance
time curl "http://$PI_HOST:8080/search?q=bitcoin&format=json"

# Freqtrade API response time
time curl "http://$PI_HOST:8081/api/v1/available_pairs"

# Container resource usage
ssh $PI_USER@$PI_HOST "docker stats --no-stream"
```

## 🔄 Common Development Tasks

### **Adding New Search Engines to SearxNG**
1. Edit `docker/services/searxng/settings.yml`
2. Add engine configuration:
```yaml
- name: new_engine
  engine: json_engine
  search_url: https://api.example.com/search?q={query}
  url_query: results[*].url
  title_query: results[*].title
  content_query: results[*].description
```
3. Deploy: `./scripts/update.sh`
4. Test: `curl "http://$PI_HOST:8080/search?q=test&engines=new_engine&format=json"`

### **Adding Crypto Exchanges to Freqtrade**
1. Edit `docker/services/freqtrade/config.json`
2. Update exchange configuration:
```json
{
  "exchange": {
    "name": "binance",  // or coinbase, kraken, etc.
    "sandbox": false,
    "pair_whitelist": ["BTC/USDT", "ETH/USDT", "ADA/USDT"]
  }
}
```
3. Deploy: `./scripts/update.sh`
4. Test: `curl "http://$PI_HOST:8081/api/v1/available_pairs"`

### **Workflow Development & Management**

#### **Setting Up Workflow References**
```bash
# Download 2000+ community workflow examples
./scripts/download-workflow-sources.sh

# Update reference library
./scripts/download-workflow-sources.sh

# Clean and re-download
./scripts/download-workflow-sources.sh clean
```

#### **Managing Your Workflows**
```bash
# Import local workflows to n8n
./scripts/sync-workflows.sh

# Export n8n workflows to local backup
./scripts/sync-workflows.sh export

# Watch for changes and auto-sync
./scripts/sync-workflows.sh watch
```

#### **Creating N8N Workflow Templates**
1. Create workflow in N8N UI
2. Export as JSON: Settings → Export
3. Save to `workflows/n8n/your-workflow.json`
4. Sync: `./scripts/sync-workflows.sh`
5. Document in README.md

#### **Using Community References**
- Browse `workflow-references/` for examples
- Search by service: "telegram", "slack", "gmail", etc.
- Copy node configurations from similar workflows
- Perfect for AI-assisted development with Cursor

### **Modifying Deployment Process**
1. Edit `ansible/playbooks/deploy.yml` for deployment steps
2. Edit `scripts/deploy.sh` for local orchestration
3. Test on fresh Pi: `./scripts/deploy.sh`

## 🐛 Debugging Common Issues

### **Ansible Connection Problems**
```bash
# Test SSH connectivity
ansible all -i "PI_HOST," -u $PI_USER --private-key=$PI_SSH_KEY -m ping

# Test with verbose output
./scripts/deploy.sh -vvv
```

### **Docker Build Issues**
```bash
# Check Pi Docker status
ssh $PI_USER@$PI_HOST "sudo systemctl status docker"

# Clean and rebuild
ssh $PI_USER@$PI_HOST "cd /opt/homeai && docker-compose down && docker system prune -f"
./scripts/update.sh
```

### **Service Startup Problems**
```bash
# Check systemd service
ssh $PI_USER@$PI_HOST "sudo journalctl -u homeai -f"

# Check individual containers
ssh $PI_USER@$PI_HOST "cd /opt/homeai && docker-compose logs searxng"
```

## 🤝 Contributing Guidelines

### **Before Submitting PRs**
1. **Test thoroughly** on your own Pi
2. **Update documentation** if you change functionality
3. **Follow existing code style** and patterns
4. **Test all scripts** work from fresh clone
5. **Verify backward compatibility**

### **Contribution Ideas**
- 🔍 **New SearxNG engines** for specific data sources
- 📊 **Additional Freqtrade exchanges** or indicators
- 🔄 **Example N8N workflows** for common use cases
- 🐛 **Bug fixes** and performance improvements
- 📚 **Documentation** improvements and translations
- 🔧 **Deployment enhancements** (Docker optimization, etc.)

### **Code Review Process**
1. Fork repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and test on Pi
4. Submit pull request with:
   - Clear description of changes
   - Testing instructions
   - Screenshots if UI changes
   - Updated documentation

## 📊 Development Metrics

### **Performance Benchmarks**
- **Fresh deployment**: 2-3 minutes on Pi 4
- **Service startup**: 30-60 seconds after reboot
- **SearxNG search**: <500ms average response
- **Freqtrade API**: <100ms for status calls
- **N8N workflow execution**: Varies by workflow complexity

### **Resource Usage (Pi 4, 4GB)**
- **Total RAM usage**: ~2GB under normal load
- **Storage**: ~8GB for all services + data
- **CPU**: 10-30% during normal operation
- **Network**: Minimal (local network only)

## 🔒 Security Considerations for Development

### **Development Pi Security**
- Use separate Pi for development testing
- Don't expose development Pi to internet
- Use strong SSH keys (ed25519 recommended)
- Regularly update Pi OS: `sudo apt update && sudo apt upgrade`

### **Code Security**
- Never commit secrets to git (use .gitignore)
- Keep config.env local only
- Sanitize any example data in PRs
- Test with minimal permissions first

---

Happy coding! 🚀 If you run into issues, check the [main README](../README.md) troubleshooting section or open an issue. 