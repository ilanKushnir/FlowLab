# FlowLab MCP Configuration

This folder contains the Model Context Protocol (MCP) configuration for FlowLab, enabling AI-powered development with Cursor IDE.

## 🚀 Quick Setup

### 1. Install MCP Servers
```bash
# From the project root
./scripts/setup-mcp.sh
```

### 2. Configure Environment
```bash
# Copy and edit the environment file
cp mcp/mcp.env.example mcp/.env
nano mcp/.env  # Add your API keys
```

### 3. Enable in Cursor
1. Open Cursor IDE
2. Go to **Settings** → **Features** → **Model Context Protocol**
3. Enable MCP
4. Set configuration file path: `mcp/mcp.json`
5. Restart Cursor

## 📁 Files

- **`mcp.json`** - Main MCP server configuration for Cursor
- **`mcp.env.example`** - Environment variables template
- **`.env`** - Your actual environment variables (gitignored)
- **`README.md`** - This documentation

## 🤖 Available MCP Servers

### 🔧 flowlab-n8n
Direct N8N workflow management and automation
- Create workflows programmatically
- Manage N8N nodes and connections
- Execute workflows remotely

### 🔍 brave-search
Web search capabilities for research
- Search the web for current information
- Get search results in structured format
- Research topics and trends

### 🌐 searxng-local
Privacy-focused local search integration
- Use your local SearXNG instance
- Private search without tracking
- Integrated with your FlowLab deployment

### 🌤️ weather
Weather data access for location-based workflows
- Get current weather conditions
- Forecast data for automation
- Location-based triggers

### 💰 crypto-data
Cryptocurrency market data and analysis
- Real-time price data
- Market trends and analysis
- Trading signal generation

## 🎯 Usage Examples

Once MCP is configured in Cursor, you can use natural language prompts like:

```
"Create an N8N workflow that monitors Bitcoin price and sends Telegram alerts when it drops below $50,000"

"Search for recent news about Ethereum and create a sentiment analysis workflow"

"Build a weather-based notification system that alerts me when it's going to rain"

"Generate a crypto trading signal workflow using RSI and MACD indicators"
```

## 🔧 Environment Variables

Required environment variables in `mcp/.env`:

```bash
# N8N API Configuration
N8N_API_KEY=your-n8n-api-key-here
N8N_USER=admin
N8N_PASSWORD=your-n8n-password

# External API Keys
BRAVE_API_KEY=your-brave-search-api-key
WEATHER_API_KEY=your-weather-api-key
COINGECKO_API_KEY=your-coingecko-pro-api-key

# Optional APIs
OPENAI_API_KEY=your-openai-api-key
SERPER_API_KEY=your-serper-api-key
```

## 🔒 Security

- The `.env` file is gitignored and won't be committed
- API keys are loaded from environment variables
- All communication with your Pi stays on your local network
- No external services have access to your private data

## 🛠️ Troubleshooting

### MCP Servers Not Loading
1. Ensure Node.js 18+ is installed
2. Run `./scripts/setup-mcp.sh` to install servers
3. Check that environment variables are set in `mcp/.env`
4. Restart Cursor after configuration changes

### N8N Connection Issues
1. Verify your Pi is accessible at the configured IP
2. Check that N8N is running on port 5678
3. Ensure API credentials are correct in `mcp/.env`

### API Key Errors
1. Verify all API keys are valid and active
2. Check API quotas and limits
3. Ensure environment variables are properly formatted

## 📚 Additional Resources

- [MCP Protocol Documentation](https://modelcontextprotocol.io/)
- [n8n-nodes-mcp GitHub](https://github.com/nerding-io/n8n-nodes-mcp)
- [Cursor MCP Guide](https://docs.cursor.com/context/model-context-protocol)
- [N8N Documentation](https://docs.n8n.io/)

---

**💡 With MCP configured, Cursor becomes your AI-powered FlowLab assistant!** 