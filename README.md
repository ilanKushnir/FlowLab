# 🧪 FlowLab

> **One-command deployment of N8N automation platform with privacy-focused tools**

**FlowLab** is a deployment wrapper that sets up [N8N](https://n8n.io) (the powerful open-source workflow automation platform) on your Raspberry Pi along with complementary privacy-focused tools. Deploy N8N + SearxNG + Freqtrade + management tools in 5 minutes.

## 🚀 **What FlowLab Provides**

**🎯 N8N + Privacy Stack**
- **[N8N](https://n8n.io)** - Visual workflow automation (400+ integrations)
- **[SearxNG](https://github.com/searxng/searxng)** - Private search engine (no tracking)
- **[Freqtrade](https://www.freqtrade.io/)** - Crypto market data API
- **[Portainer](https://www.portainer.io/)** - Container management
- **2000+ workflow examples** from the N8N community

**🛠️ Deployment & Tools**
- **One-command deployment** - Automated Ansible setup
- **Workflow sync scripts** - Keep N8N workflows in your repo
- **Community workflow library** - Download and browse examples locally
- **Privacy by design** - Everything runs on your network

[![Deploy](https://img.shields.io/badge/Deploy-One%20Command-green?style=for-the-badge)](./scripts/deploy.sh)
[![Cost Savings](https://img.shields.io/badge/Cost%20Savings-97%25-brightgreen?style=for-the-badge)](#-cost-comparison)
[![Self Hosted](https://img.shields.io/badge/Self%20Hosted-100%25%20Private-blue?style=for-the-badge)](#-yours-private)

---

## ⚡ **Deploy N8N in 5 Minutes**

### **Prerequisites**
- Raspberry Pi 4 (4GB+ RAM) with Raspberry Pi OS
- SSH enabled + Ansible installed on your computer

### **1. Clone & Configure**
```bash
git clone https://github.com/your-username/flowlab.git
cd flowlab
cp config.env.example config.env
nano config.env  # Set your Pi IP and SSH key
```

### **2. Deploy Everything**
```bash
./scripts/deploy.sh
```

### **3. Access Your Services**
```
🎯 N8N Automation     → http://YOUR_PI_IP:5678
🔍 SearxNG Search     → http://YOUR_PI_IP:8080  
📊 Freqtrade API     → http://YOUR_PI_IP:8081
🐳 Portainer         → http://YOUR_PI_IP:9000
```

### **4. Get Workflow Examples**
```bash
# Download 2000+ N8N community workflows
./scripts/download-workflow-sources.sh
```

## 🛠️ **Management Commands**

```bash
# Deploy/update your N8N stack
./scripts/deploy.sh
./scripts/update.sh

# Sync N8N workflows with your repo
./scripts/sync-workflows.sh
./scripts/sync-workflows.sh export

# Debug and monitor
./scripts/helpers/logs.sh
```

## 🔍 **APIs for N8N Workflows**

```bash
# SearxNG private search
curl "http://YOUR_PI_IP:8080/search?q=bitcoin&format=json"

# Freqtrade market data
curl "http://YOUR_PI_IP:8081/api/v1/available_pairs"
curl "http://YOUR_PI_IP:8081/api/v1/pair_candles?pair=BTC/USDT&timeframe=1h"
```

## 💰 **Cost Comparison**

| Service | Enterprise SaaS | FlowLab | Annual Savings |
|---------|----------------|---------|----------------|
| 🤖 **N8N Automation** | Zapier Pro ($50/mo) | **FREE** | **$600** |
| 📰 **Search API** | SerpAPI ($100/mo) | **FREE** | **$1,200** |
| 📊 **Market Data** | TAAPI.io ($29/mo) | **FREE** | **$348** |
| 🐳 **Infrastructure** | DigitalOcean ($20/mo) | **FREE** | **$240** |
| **🔥 TOTAL** | **$199/month** | **$20/year*** | **🎯 $2,388/year** |

***Only cost: Raspberry Pi electricity (~$20/year)**

> 💡 **ROI**: Your $100 Pi investment pays for itself in 2 months!

## 🤝 **Contributing**

FlowLab wraps amazing open-source projects:
- **[N8N](https://n8n.io)** - The incredible workflow automation platform
- **[SearxNG](https://github.com/searxng/searxng)** - Privacy-focused search
- **[Freqtrade](https://www.freqtrade.io/)** - Crypto trading framework

**Want to contribute to FlowLab?**
- 🔧 Improve deployment scripts
- 📚 Add workflow examples  
- 🐛 Fix issues and bugs
- 📖 Enhance documentation

## 📚 **Documentation**

- **[Setup Guide](./docs/SETUP.md)** - Detailed setup instructions
- **[Workflow Library](./docs/WORKFLOW_REFERENCES.md)** - Community workflow docs
- **[Troubleshooting](./docs/DEPLOYMENT_FIXES.md)** - Common solutions

## 📄 **License**

MIT License - FlowLab deployment scripts and tools are free to use and modify!

---

## 🚀 **Ready to Deploy N8N?**

**Stop paying for automation subscriptions. Start building with N8N on your own hardware.**

### **Quick Start**
1. **Clone this repo** 
2. **Edit config.env**
3. **Run `./scripts/deploy.sh`**
4. **Start building N8N workflows**

**Questions?** Open an issue - we're here to help!

---

**💡 FlowLab makes N8N deployment effortless. Your automation journey starts here! 🧪** 