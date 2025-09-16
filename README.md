# Coder Modules

A collection of reusable Terraform modules for extending [Coder](https://coder.com/) workspace functionality. These modules provide easy integration of popular development tools, applications, and services into your Coder workspace templates.

## 🚀 Available Modules

### Development Tools

#### [Claude Code](./claude-code/)
Integrate Anthropic's Claude Code AI assistant directly into your workspace.

**Features:**
- Web-based Claude Code interface with task reporting
- Optional CLI access through AgentAPI
- Automatic Node.js/npm installation via NVM
- Configurable installation scripts (pre/post-install)
- AgentAPI integration for enhanced AI capabilities

**Usage:**
```hcl
module "claude_code" {
  source   = "git::https://github.com/AI-Riksarkivet/coder-modules.git//claude-code?ref=main"
  agent_id = coder_agent.main.id

  # Optional configuration
  folder                    = "/home/coder"
  claude_code_version      = "latest"
  experiment_report_tasks  = true
  install_agentapi         = true
}
```

### Desktop Environments

#### [KasmVNC](./kasmvnc/)
High-performance, containerized VNC server for remote desktop access.

**Features:**
- Support for multiple desktop environments (XFCE, KDE, GNOME, LXDE, LXQT)
- Configurable ports and versions
- Built-in health checking
- Web-based access through browser

**Usage:**
```hcl
module "kasmvnc" {
  source              = "git::https://github.com/AI-Riksarkivet/coder-modules.git//kasmvnc?ref=main"
  agent_id            = coder_agent.main.id
  desktop_environment = "xfce"
  port                = 6800
}
```

### Data Science & Analytics

#### [Langflow](./langflow/)
Visual framework for building multi-agent and RAG applications.

**Features:**
- Drag-and-drop interface for AI workflows
- Configurable base paths and ports
- Health monitoring and logging
- Subdomain support

**Usage:**
```hcl
module "langflow" {
  source    = "git::https://github.com/AI-Riksarkivet/coder-modules.git//langflow?ref=main"
  agent_id  = coder_agent.main.id
  port      = 7860
  subdomain = true
}
```

#### [Marimo](./marimo/)
Reactive Python notebooks that are reproducible, git-friendly, and deployable as scripts or apps.

**Features:**
- Interactive Python notebook environment
- Git-friendly notebook format
- Real-time reactivity and execution
- Health monitoring with configurable paths

**Usage:**
```hcl
module "marimo" {
  source   = "git::https://github.com/AI-Riksarkivet/coder-modules.git//marimo?ref=main"
  agent_id = coder_agent.main.id
  port     = 2818
}
```

#### [FiftyOne](./fiftyone/)
Open-source toolkit for building high-quality datasets and computer vision models.

**Features:**
- Dataset visualization and exploration
- Model evaluation and analysis
- Label and annotation management
- Automatic setup and configuration

**Usage:**
```hcl
module "fiftyone" {
  source   = "git::https://github.com/AI-Riksarkivet/coder-modules.git//fiftyone?ref=main"
  agent_id = coder_agent.main.id
  port     = 5151
}
```

### Communication & Notifications

#### [SlackMe](./slackme/)
Command-line utility for sending notifications to Slack channels.

**Features:**
- Integration with Coder's external auth providers
- Customizable message templates
- Default channel configuration
- Command completion notifications

**Usage:**
```hcl
module "slackme" {
  source           = "git::https://github.com/AI-Riksarkivet/coder-modules.git//slackme?ref=main"
  agent_id         = coder_agent.main.id
  auth_provider_id = coder_external_auth.slack.id
  default_channel  = "#dev-notifications"
}
```

## 📋 Module Structure

Each module follows consistent patterns:

```
module-name/
├── main.tf              # Main Terraform configuration
├── run.sh              # Installation/startup script (if applicable)
├── scripts/            # Additional helper scripts
└── README.md           # Module-specific documentation
```

## 🛠️ Common Configuration

### Required Variables
All modules require:
- `agent_id` - The ID of the Coder agent to install the module on

### Optional Variables
Most modules support:
- `port` - Port number for web applications (module-specific defaults)
- `subdomain` - Enable subdomain routing for web apps
- `share` - Access level (`owner`, `authenticated`, `public`)
- `order` - UI display order
- `group` - Logical grouping in the UI

## 🚀 Quick Start

1. **Add Module to Template**: Include the module in your Coder workspace template:

```hcl
terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 2.0"
    }
  }
}

resource "coder_agent" "main" {
  arch = "amd64"
  os   = "linux"
  # ... agent configuration
}

# Add any module
module "claude_code" {
  source   = "git::https://github.com/AI-Riksarkivet/coder-modules.git//claude-code?ref=main"
  agent_id = coder_agent.main.id
}
```

2. **Apply Template**: Deploy the template to your Coder instance
3. **Create Workspace**: Launch a new workspace with the integrated modules

## 🔧 Development

### Adding New Modules

1. Create a new directory with the module name
2. Add `main.tf` with Terraform configuration
3. Include installation scripts if needed
4. Add health checks for web applications
5. Update this README with module documentation

### Testing Modules

Test modules by:
1. Creating a test workspace template
2. Including the module with various configurations
3. Verifying application startup and functionality
4. Testing health checks and UI integration

## 📚 Module Details

### Web Application Modules
Web-based modules (`langflow`, `marimo`, `fiftyone`, `kasmvnc`) include:
- **Health Checks**: Automatic monitoring of application availability
- **Subdomain Support**: Optional subdomain routing for cleaner URLs
- **Access Control**: Configurable sharing permissions
- **Logging**: Structured logging to specified paths

### Utility Modules
Utility modules (`claude-code`, `slackme`) provide:
- **Installation Scripts**: Automated setup and configuration
- **External Integrations**: Authentication and service connections
- **Custom Commands**: CLI tools and shortcuts

## 🤝 Contributing

1. **Fork Repository**: Create your own fork
2. **Create Module**: Follow the established patterns
3. **Test Thoroughly**: Verify functionality across environments
4. **Update Documentation**: Include comprehensive usage examples
5. **Submit PR**: Create pull request with detailed description

## 📖 Resources

- **[Coder Documentation](https://coder.com/docs)**: Official Coder platform documentation
- **[Terraform Coder Provider](https://registry.terraform.io/providers/coder/coder/latest/docs)**: Provider documentation
- **[Module Development Guide](https://developer.hashicorp.com/terraform/language/modules)**: Terraform module best practices

## 🆘 Support

For issues and questions:
- **Module Issues**: Create GitHub issues with detailed descriptions
- **Coder Platform**: Reference official Coder documentation and support
- **Integration Help**: Check individual module README files for specific guidance

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.