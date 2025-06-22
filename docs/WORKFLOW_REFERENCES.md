# 📚 Workflow References System

This system automatically downloads curated n8n workflow collections for use as reference and context when building new workflows.

## 🎯 Purpose

- **Reference Library**: Download thousands of community workflows locally
- **Cursor Context**: Use as context when building workflows with AI assistance
- **Learning Resource**: Study patterns and best practices from the community
- **Version Control**: Keep references separate from your actual workflows

## 🚀 Quick Start

### Download all workflow references:
```bash
./scripts/download-workflow-sources.sh
```

### Clean up downloaded references:
```bash
./scripts/download-workflow-sources.sh clean
```

## 📋 Available Sources

The system downloads workflows from these curated sources:

### 🌟 Main Collection
- **[Zie619 Community Workflows](https://github.com/Zie619/n8n-workflows)** - 2000+ community workflows
  - Categories: Automation, APIs, Integrations, Business Logic
  - Quality: Community-driven, well-documented
  - **Most comprehensive collection available**

### 🏢 Official Sources  
- **[N8N Official Examples](https://github.com/n8n-io/n8n)** - Official workflow templates
  - Categories: Starter templates, Official patterns
  - Quality: Production-ready, officially supported

### 👥 Community Contributors
- **Additional sources** from active n8n community members
  - Quality workflow patterns and examples
  - Specialized use cases and integrations

## 📁 Structure

```
workflow-references/           # Downloaded workflows (gitignored)
├── INDEX.md                  # Overview of all sources
├── zie619-community-workflows/  # Main collection
│   ├── .source-info.md       # Source metadata
│   ├── banking/              # Banking workflows
│   ├── social-media/         # Social media automation
│   ├── e-commerce/           # E-commerce workflows
│   └── ...                   # 50+ categories
├── n8n-official-examples/    # Official templates
└── other-sources/            # Additional collections
```

## 🔍 How to Use with Cursor

### 1. **Open References in Cursor**
```bash
# Add workflow-references folder to your Cursor workspace
# This gives AI context about workflow patterns
```

### 2. **Search for Patterns**
- **By Service**: Search "slack", "gmail", "notion" etc.
- **By Pattern**: Search "webhook", "schedule", "if node" etc.  
- **By Use Case**: Search "email automation", "data sync" etc.

### 3. **Copy Useful Patterns**
- Find relevant workflow examples
- Copy node configurations and connections
- Adapt patterns to your specific needs

### 4. **Learn Best Practices**
- Study error handling patterns
- Learn efficient node arrangements
- Understand common workflow structures

## ⚙️ Adding New Sources

Edit `workflow-sources.yaml` to add new repositories:

```yaml
sources:
  - name: "my-custom-source"
    description: "Description of the source"
    type: "github"
    url: "https://github.com/user/repo"
    path: "workflows"  # Optional subdirectory
    tags: ["tag1", "tag2"]
```

Then run:
```bash
./scripts/download-workflow-sources.sh
```

## 🔄 Keeping References Updated

Re-run the download script periodically to get the latest workflows:

```bash
# Update all sources
./scripts/download-workflow-sources.sh

# Or set up a weekly cron job
0 0 * * 0 cd /path/to/project && ./scripts/download-workflow-sources.sh
```

## 💡 Pro Tips

### **For Workflow Development:**
1. **Start with references** - Browse similar workflows first
2. **Copy-paste nodes** - Don't rebuild common patterns
3. **Study error handling** - Learn from robust examples
4. **Use as templates** - Start with existing workflows and modify

### **For Learning:**
1. **Browse by category** - Focus on your use case
2. **Study complex workflows** - Learn advanced patterns
3. **Compare approaches** - See different solutions to same problems
4. **Read documentation** - Many workflows have great comments

### **For Team Development:**
1. **Share patterns** - Reference common solutions
2. **Standardize approaches** - Use proven patterns
3. **Code reviews** - Compare against best practices
4. **Documentation** - Reference community examples

## 🔧 Configuration

The download behavior is configured in `workflow-sources.yaml`:

```yaml
download:
  target_directory: "workflow-references"  # Where to download
  organize_by_source: true                 # Separate by source
  include_patterns: ["*.json", "*.md"]     # File types to download
  exclude_patterns: ["node_modules"]      # Skip these folders
```

## 📊 Statistics

After downloading, you'll have access to:
- **2000+ workflow files** from the community
- **50+ categories** of automation patterns  
- **Every major service integration** (Slack, Gmail, Notion, etc.)
- **Advanced patterns** (error handling, loops, conditions)
- **Real-world examples** from production systems

## 🤝 Contributing

To add valuable workflow sources:

1. Find high-quality n8n workflow repositories
2. Add them to `workflow-sources.yaml`
3. Test the download script
4. Submit a PR with the addition

---

**Perfect for**: Learning n8n patterns, building complex workflows, team standardization, AI-assisted development with Cursor. 