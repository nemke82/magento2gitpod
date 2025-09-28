# Magento 2 Development Environment for ONA Platform (formerly Magento 2 Gitpod)

A modern, fully-configured Magento 2.4.8 development environment optimized for [ONA Platform](https://ona.com) (formerly Gitpod) with configurable versions, MariaDB, and comprehensive tooling.

[![Open in ONA](https://ona.com/button/open-in-ona.svg)](https://ona.com/#https://github.com/nemke82/magento2gitpod)

## 🚀 Quick Start

### 1. Environment Setup

**For ONA Cloud:**
1. Fork this repository
2. Install the [Gitpod browser extension](https://chrome.google.com/webstore/detail/gitpod-online-ide/dodmmooeoklaejobgleioelladacbeki) Firefox: https://addons.mozilla.org/en-US/firefox/addon/onahq/ (still works with ONA)
3. Click the ONA button above or visit `https://ona.com/#https://github.com/your-username/magento2gitpod`

**For ONA Self-Hosted:**
1. Configure your ONA self-hosted instance
2. Open the repository in your ONA environment
3. The devcontainer will automatically build and configure

### 2. Once Environment Starts

The environment provides several commands to manage services:

#### Essential Commands

```bash
# Check versions and available commands
versions

# Start core services (MariaDB, Redis, PHP-FPM, Nginx)
start-core

# Start all services (includes RabbitMQ)
start-all

# Check service status
status-all

# Test database connection
test-db
```

#### Service Management

```bash
# Core services (faster startup, recommended for development)
start-core      # Start MariaDB, Redis, PHP-FPM, Nginx
status-all      # Check all service status
stop-all        # Stop all services
restart-all     # Restart all services

# Full services (includes RabbitMQ)
start-all       # Start everything including RabbitMQ
```

### 3. Install Magento 2

After services are running, install Magento 2:

```bash
# For latest Magento 2.4.8 release
./m2-install.sh

# For development branch (bleeding edge)
./m2-install-solo.sh
```

## 🛠️ Technology Stack

### Core Components
- **PHP**: 8.2 (configurable via devcontainer.json)
- **Database**: MariaDB 10.6 (configurable)
- **Web Server**: Nginx with optimized Magento 2 configuration
- **Process Manager**: PHP-FPM 8.2
- **Cache**: Redis 7.0
- **Search**: Opensearch 2.19 + legacy versions (5.6, 6.8, 7.9)
- **Queue**: RabbitMQ with management interface
- **Package Manager**: Composer 2.6.6
- **Runtime**: Node.js 18.19.0 via NVM

### Development Tools
- **Debugging**: Xdebug 3.x (disabled by default)
- **Code Quality**: n98-magerun2
- **Performance**: Blackfire (configurable)
- **Monitoring**: New Relic (optional install)
- **Browser Testing**: Chrome + ChromeDriver
- **File Manager**: Midnight Commander (mc)

## 📊 Default Configuration

### Database Settings
- **Host**: localhost
- **Port**: 3306
- **Username**: root
- **Password**: nem4540
- **Default Database**: magento2

### Service Ports
- **Web Server**: 8002 (HTTPS)
- **RabbitMQ Management**: 15672 (HTTPS)
- **MariaDB**: 3306 (Internal)
- **Redis**: 6379 (Internal)
- **Opensearch**: 9200 (Internal)

## 🔧 Customizing Versions

Update `devcontainer.json` to change software versions:

```json
{
  "build": {
    "args": {
      "PHP_VERSION": "8.1",           // Change PHP version
      "MARIADB_VERSION": "10.8",      // Change MariaDB version
      "OPENSEARCH_VERSION": "2.19.0", // Change Opensearch
      "NODE_VERSION": "20.0.0",       // Change Node.js version
      "COMPOSER_VERSION": "2.7.0"     // Change Composer version
    }
  }
}
```

After changing versions:
1. In VS Code: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"
2. Or from command palette: "Dev Containers: Rebuild and Reopen in Container"

## 🎮 Available Commands

### Service Management
```bash
start-core      # Quick start (MariaDB, Redis, PHP-FPM, Nginx)
start-all       # Full start (includes RabbitMQ)
stop-all        # Stop all services
restart-all     # Restart all services
status-all      # Check service status
```

### Database Operations
```bash
test-db         # Test MariaDB connection
fix-mysql       # Fix MariaDB authentication issues
mysql           # Connect to MariaDB (alias for mariadb)
```

### Development Tools
```bash
magento         # Magento CLI (alias for php bin/magento)
magerun         # n98-magerun2 tool
versions        # Show installed versions
```

### Debugging & Performance
```bash
xdebug-on       # Enable Xdebug
xdebug-off      # Disable Xdebug
blackfire-config # Configure Blackfire monitoring
newrelic-install # Install New Relic monitoring
```

### RabbitMQ Management
```bash
rabbitmq-config    # Setup RabbitMQ users and permissions
rabbitmq-diagnose # Troubleshoot RabbitMQ issues
```

## 🐛 Debugging Setup

### Xdebug Configuration
```bash
# Enable Xdebug for debugging
xdebug-on

# Configure your IDE to listen on port 9003
# Xdebug is pre-configured for ONA environment
```

### Performance Monitoring

**Blackfire Setup:**
```bash
blackfire-config
# Enter your Blackfire credentials when prompted
```

**New Relic Setup:**
```bash
newrelic-install
# Follow the installation prompts
```

## 🗄️ Database Management

### Quick Database Tasks
```bash
# Connect to database
mysql

# Create additional database
mysql -e "CREATE DATABASE my_project;"

# Import database
mysql magento2 < backup.sql

# Export database
mysqldump magento2 > backup.sql
```

### MariaDB Authentication
The environment uses MariaDB 10.6 with password authentication (not unix_socket). If you encounter authentication issues:

```bash
# Fix authentication
fix-mysql

# Test connection
test-db
```

## 🔄 Container Persistence

The devcontainer configuration includes persistent volumes:
- **MySQL Data**: Persistent across container rebuilds
- **Composer Cache**: Speeds up package installations
- **NPM Cache**: Faster Node.js operations

## 📱 Service URLs

Once services are running:
- **Magento Store**: Exposed on port 8002 (auto-HTTPS in ONA)
- **RabbitMQ Management**: Exposed on port 15672
  - Username: `admin` / Password: `admin`
  - Or: `guest` / `guest`
- **CloudBeaver (DB Manager)**: Exposed on port 8003 (public when task runs)
  - Connect in CloudBeaver to `host.docker.internal:3306` with `root` / `nem4540`
- **MailHog**: Web UI on port 8025 (public when task runs); SMTP on port 1025 (internal)

## 📦 Optional Tools: CloudBeaver & MailHog

### CloudBeaver (DB Manager)
- Start via ONA Automations: open the Automations panel and run task `CloudBeaver (DB Manager)`.
- The task ensures MariaDB is running, opens DB bind-address for external connections, grants root access, starts the CloudBeaver container, and exposes port 8003 publicly in ONA.
- Open the public URL on port 8003 and create a connection to `host.docker.internal` on port `3306` with `root` / `nem4540`.
- Stop with the `Stop CloudBeaver` task.

### MailHog (Email service simulator)
- Start via ONA Automations: run task `MailHog (Mail Catcher)`.
- The task installs `mhsendmail`, configures PHP `sendmail_path` to route `mail()` to MailHog, starts the container, and exposes the web UI on port 8025 publicly in ONA.
- Visit the public URL on port 8025 to view captured emails. SMTP listens on port 1025 (internal).
- Stop with the `Stop MailHog` task.

## 🔍 Troubleshooting

### Service Issues
```bash
# Check all service status
status-all

# View service logs
sudo journalctl -u mariadb
sudo journalctl -u redis-server
```

### Database Issues
```bash
# Test database connection
test-db

# Fix common authentication issues
fix-mysql

# Check MariaDB logs
sudo tail -f /var/log/mysql/error.log
```

### RabbitMQ Issues
```bash
# Diagnose RabbitMQ problems
rabbitmq-diagnose

# Reconfigure RabbitMQ
rabbitmq-config
```

## 🚀 Performance Tips

1. **Use start-core for development**: Faster startup, includes essential services
2. **Enable persistent volumes**: Configured by default in devcontainer.json
3. **Customize resource allocation**: Update hostRequirements in devcontainer.json
4. **Use Blackfire for profiling**: Run `blackfire-config` to set up


## 🔄 Migration from Legacy Gitpod

If you're migrating from the original Gitpod setup:

1. **Environment Variables**: Update any hardcoded `.gitpod.io` domains to `.ona.dev`
2. **Configuration Files**: Review `.gitpod.yml` and `.gitpod.Dockerfile` for ONA compatibility
3. **Agent Integration**: Leverage new ONA Agent capabilities for enhanced development
4. **Security Policies**: Configure organizational policies for team development

## 📚 Additional Resources

- **ONA Documentation**: [docs.ona.com](https://docs.ona.com)
- **Magento DevDocs**: [devdocs.magento.com](https://devdocs.magento.com)
- **Video Tutorial**: [Magento 2 in Browser Setup](https://youtu.be/ZydOkPWJPT8)
- **Changelog**: [Project Changelog](https://github.com/nemke82/magento2gitpod/wiki/Changelog)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/nemke82/magento2gitpod/issues)
- **ONA Support**: [support.ona.com](https://support.ona.com)
- **Community**: [ONA Discord](https://discord.gg/ona)

---

**🌟 Star this repository if it helps your Magento 2 development workflow!**

> Built with ❤️ for the Magento community | Powered by ONA Platform
