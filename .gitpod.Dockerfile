# Modern Magento 2 Development Environment for Ona
# With configurable versions via build arguments

FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# ==============================================
# BUILD ARGUMENTS - Configurable Versions
# ==============================================
ARG PHP_VERSION=8.2
ARG MARIADB_VERSION=10.6
ARG ELASTICSEARCH_VERSION=8.11.4
ARG NODE_VERSION=18.19.0
ARG COMPOSER_VERSION=2.6.6
ARG REDIS_VERSION=7.0

# Legacy versions (can be overridden)
ARG PHP_LEGACY_VERSION=7.4
ARG ELASTICSEARCH_LEGACY_56=5.6.16
ARG ELASTICSEARCH_LEGACY_68=6.8.9
ARG ELASTICSEARCH_LEGACY_79=7.9.3

# ==============================================
# ENVIRONMENT VARIABLES
# ==============================================
ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_VERSION=${PHP_VERSION}
ENV MARIADB_VERSION=${MARIADB_VERSION}
ENV ELASTICSEARCH_VERSION=${ELASTICSEARCH_VERSION}
ENV NODE_VERSION=${NODE_VERSION}
ENV MYSQL_ROOT_PASSWORD=nem4540
ENV MYSQL_DATABASE=magento2
ENV WORKSPACE_DIR="/workspaces/magento2gitpod"
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_MEMORY_LIMIT=-1

# Blackfire settings
ENV BLACKFIRE_LOG_LEVEL=1
ENV BLACKFIRE_LOG_FILE=/var/log/blackfire/blackfire.log
ENV BLACKFIRE_SOCKET=unix:///tmp/agent.sock
ENV BLACKFIRE_SOURCEDIR=/etc/blackfire
ENV BLACKFIRE_USER=vscode

# NVM and Elasticsearch paths
ENV NVM_DIR=/usr/local/nvm
ENV ES_HOME="/home/vscode/elasticsearch-${ELASTICSEARCH_VERSION}"
ENV ES_HOME56="/home/vscode/elasticsearch-${ELASTICSEARCH_LEGACY_56}"
ENV ES_HOME68="/home/vscode/elasticsearch-${ELASTICSEARCH_LEGACY_68}" 
ENV ES_HOME79="/home/vscode/elasticsearch-${ELASTICSEARCH_LEGACY_79}"

# ==============================================
# SYSTEM SETUP
# ==============================================
USER root

# Create workspace and set ownership
RUN mkdir -p /workspaces/magento2gitpod && \
    chown -R vscode:vscode /workspaces

# Update system and install base dependencies
RUN apt-get update && apt-get install -y \
    lsb-release \
    apt-utils \
    python3 \
    python3-pip \
    python3-venv \
    libmysqlclient-dev \
    rsync \
    curl \
    wget \
    unzip \
    zip \
    git \
    vim \
    nano \
    tree \
    htop \
    ncdu \
    jq \
    libnss3-dev \
    openssh-client \
    mc \
    software-properties-common \
    gcc \
    make \
    autoconf \
    libc-dev \
    pkg-config \
    libmcrypt-dev \
    php-dev \
    php-pear \
    dialog \
    supervisor \
    gnupg2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ==============================================
# PHP INSTALLATION AND CONFIGURATION
# ==============================================

# Add Ondrej PHP repository
RUN add-apt-repository ppa:ondrej/php -y && \
    apt-get update

# Install PHP and extensions
RUN apt-get install -y \
    php${PHP_VERSION} \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-readline \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-msgpack \
    php${PHP_VERSION}-igbinary \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-memcached \
    php${PHP_VERSION}-sqlite3 \
    php${PHP_VERSION}-apcu \
    php${PHP_VERSION}-imagick \
    php${PHP_VERSION}-xdebug \
    php${PHP_VERSION}-dev \
    && rm -rf /var/lib/apt/lists/*

# Set PHP alternatives and create run directory
RUN update-alternatives --set php /usr/bin/php${PHP_VERSION} && \
    mkdir -p /run/php && \
    chown vscode:vscode /run/php

# Configure PHP settings
RUN echo "memory_limit = 4G" >> /etc/php/${PHP_VERSION}/cli/php.ini && \
    echo "max_execution_time = 1800" >> /etc/php/${PHP_VERSION}/cli/php.ini && \
    echo "zlib.output_compression = On" >> /etc/php/${PHP_VERSION}/cli/php.ini && \
    echo "opcache.memory_consumption = 512M" >> /etc/php/${PHP_VERSION}/cli/php.ini && \
    echo "opcache.max_accelerated_files = 60000" >> /etc/php/${PHP_VERSION}/cli/php.ini && \
    echo "opcache.consistency_checks = 0" >> /etc/php/${PHP_VERSION}/cli/php.ini && \
    echo "opcache.validate_timestamps = 0" >> /etc/php/${PHP_VERSION}/cli/php.ini && \
    echo "opcache.enable_cli = 1" >> /etc/php/${PHP_VERSION}/cli/php.ini

# Copy PHP-FPM settings to FPM config
RUN cp /etc/php/${PHP_VERSION}/cli/php.ini /tmp/php-settings.ini && \
    cat /tmp/php-settings.ini >> /etc/php/${PHP_VERSION}/fpm/php.ini

# Configure APCu
RUN echo "apc.enable_cli=1" > /etc/php/${PHP_VERSION}/cli/conf.d/20-apcu.ini && \
    echo "apc.enable_cli=1" > /etc/php/${PHP_VERSION}/fpm/conf.d/20-apcu.ini

# Configure Xdebug for modern debugging
RUN echo "xdebug.mode=debug" >> /etc/php/${PHP_VERSION}/mods-available/xdebug.ini && \
    echo "xdebug.start_with_request=yes" >> /etc/php/${PHP_VERSION}/mods-available/xdebug.ini && \
    echo "xdebug.client_port=9003" >> /etc/php/${PHP_VERSION}/mods-available/xdebug.ini && \
    echo "xdebug.client_host=localhost" >> /etc/php/${PHP_VERSION}/mods-available/xdebug.ini && \
    echo "xdebug.discover_client_host=1" >> /etc/php/${PHP_VERSION}/mods-available/xdebug.ini

# Disable Xdebug by default (enable via script)
RUN mv /etc/php/${PHP_VERSION}/cli/conf.d/20-xdebug.ini /etc/php/${PHP_VERSION}/cli/conf.d/20-xdebug.ini.disabled && \
    mv /etc/php/${PHP_VERSION}/fpm/conf.d/20-xdebug.ini /etc/php/${PHP_VERSION}/fpm/conf.d/20-xdebug.ini.disabled

# ==============================================
# COMPOSER INSTALLATION
# ==============================================
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION}

# ==============================================
# MARIADB INSTALLATION
# ==============================================
RUN curl -sS https://mariadb.org/mariadb_release_signing_key.asc | apt-key add - && \
    echo "deb [arch=amd64,arm64,ppc64el] https://ftp.osuosl.org/pub/mariadb/repo/${MARIADB_VERSION}/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/mariadb.list && \
    apt-get update && \
    echo "mariadb-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections && \
    echo "mariadb-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections && \
    apt-get install -y mariadb-server mariadb-client && \
    mkdir -p /var/run/mysqld && \
    chown -R vscode:vscode /var/run/mysqld /var/log/mysql && \
    rm -rf /var/lib/apt/lists/*

# ==============================================
# NGINX INSTALLATION
# ==============================================
RUN apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

# ==============================================
# REDIS INSTALLATION
# ==============================================
RUN apt-get update && \
    apt-get install -y redis-server && \
    rm -rf /var/lib/apt/lists/*

# ==============================================
# NODE.JS INSTALLATION VIA NVM
# ==============================================
RUN mkdir -p /usr/local/nvm && \
    chown vscode:vscode /usr/local/nvm

# Install NVM and Node.js as vscode user
USER vscode

# Install NVM
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install Node.js using NVM (using bash explicitly)
RUN /bin/bash -c ". $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && nvm use default"

# Verify Node.js installation
RUN /bin/bash -c ". $NVM_DIR/nvm.sh && node --version && npm --version"

# Add node and npm to path for all users
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# ==============================================
# ELASTICSEARCH INSTALLATION
# ==============================================

# Install modern Elasticsearch for Magento 2.4.8
RUN cd /home/vscode && \
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}-linux-x86_64.tar.gz && \
    tar -xzf elasticsearch-${ELASTICSEARCH_VERSION}-linux-x86_64.tar.gz && \
    rm elasticsearch-${ELASTICSEARCH_VERSION}-linux-x86_64.tar.gz

# Install legacy Elasticsearch versions (optional)
RUN cd /home/vscode && \
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_LEGACY_56}.tar.gz && \
    tar -xzf elasticsearch-${ELASTICSEARCH_LEGACY_56}.tar.gz && \
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_LEGACY_68}.tar.gz && \
    tar -xzf elasticsearch-${ELASTICSEARCH_LEGACY_68}.tar.gz && \
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_LEGACY_79}-linux-x86_64.tar.gz && \
    tar -xzf elasticsearch-${ELASTICSEARCH_LEGACY_79}-linux-x86_64.tar.gz && \
    rm *.tar.gz

# ==============================================
# ADDITIONAL TOOLS
# ==============================================

# Switch back to root for tool installations
USER root

# Install n98-magerun2
RUN wget https://files.magerun.net/n98-magerun2.phar && \
    chmod +x ./n98-magerun2.phar && \
    mv ./n98-magerun2.phar /usr/local/bin/n98-magerun2

# Install Chrome for testing (optional)
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Note: ChromeDriver and Selenium can be installed later if needed for MFTF testing
# Commands to install manually if needed:
# wget -O /usr/local/bin/selenium-server-standalone.jar https://selenium-release.storage.googleapis.com/3.141/selenium-server-standalone-3.141.59.jar
# Check latest ChromeDriver version and install accordingly

# Install Blackfire (updated method)
RUN curl -fsSL https://packages.blackfire.io/gpg.key | apt-key add - && \
    echo "deb http://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list && \
    apt-get update && \
    apt-get install -y blackfire blackfire-php && \
    rm -rf /var/lib/apt/lists/*

# Note: New Relic installation skipped for now (optional monitoring tool)
# To install New Relic manually later:
# curl -fsSL https://download.newrelic.com/548C16BF.gpg | sudo apt-key add -
# echo "deb http://apt.newrelic.com/debian/ newrelic non-free" | sudo tee /etc/apt/sources.list.d/newrelic.list
# sudo apt-get update && sudo apt-get install -y newrelic-php5
# sudo newrelic-install install

# New Relic setup script for later use
RUN echo '#!/bin/bash' > /usr/local/bin/newrelic-setup && \
    echo 'echo "Installing New Relic..."' >> /usr/local/bin/newrelic-setup && \
    echo 'curl -fsSL https://download.newrelic.com/548C16BF.gpg | sudo apt-key add -' >> /usr/local/bin/newrelic-setup && \
    echo 'echo "deb http://apt.newrelic.com/debian/ newrelic non-free" | sudo tee /etc/apt/sources.list.d/newrelic.list' >> /usr/local/bin/newrelic-setup && \
    echo 'sudo apt-get update && sudo apt-get install -y newrelic-php5' >> /usr/local/bin/newrelic-setup && \
    echo 'sudo newrelic-install install' >> /usr/local/bin/newrelic-setup && \
    echo 'echo "New Relic installed! Configure with your license key."' >> /usr/local/bin/newrelic-setup && \
    chmod +x /usr/local/bin/newrelic-setup

# Configure New Relic for PHP 8.2
RUN if [ -f /etc/php/${PHP_VERSION}/cli/conf.d/newrelic.ini ]; then \
        sed -i 's/"REPLACE_WITH_REAL_KEY"/"REPLACE_WITH_YOUR_LICENSE_KEY"/' /etc/php/${PHP_VERSION}/cli/conf.d/newrelic.ini && \
        sed -i 's/newrelic.appname = "PHP Application"/newrelic.appname = "Magento 2 Development"/' /etc/php/${PHP_VERSION}/cli/conf.d/newrelic.ini && \
        sed -i 's/;newrelic.daemon.app_connect_timeout =.*/newrelic.daemon.app_connect_timeout=15s/' /etc/php/${PHP_VERSION}/cli/conf.d/newrelic.ini && \
        sed -i 's/;newrelic.daemon.start_timeout =.*/newrelic.daemon.start_timeout=5s/' /etc/php/${PHP_VERSION}/cli/conf.d/newrelic.ini && \
        cp /etc/php/${PHP_VERSION}/cli/conf.d/newrelic.ini /etc/php/${PHP_VERSION}/fpm/conf.d/newrelic.ini; \
    fi

# Create Blackfire configuration directories and set permissions
RUN mkdir -p /var/log/blackfire /var/run/blackfire /etc/blackfire && \
    chown -R vscode:vscode /var/log/blackfire /var/run/blackfire /etc/blackfire

# Default Blackfire configuration files
RUN echo '[blackfire]' > /etc/blackfire/agent && \
    echo '; Blackfire agent configuration' >> /etc/blackfire/agent && \
    echo '; server-id=' >> /etc/blackfire/agent && \
    echo '; server-token=' >> /etc/blackfire/agent && \
    echo 'log-file=/var/log/blackfire/agent.log' >> /etc/blackfire/agent && \
    echo 'log-level=1' >> /etc/blackfire/agent

RUN echo '[blackfire]' > /etc/php/${PHP_VERSION}/cli/conf.d/92-blackfire-config.ini && \
    echo ';extension=blackfire.so' >> /etc/php/${PHP_VERSION}/cli/conf.d/92-blackfire-config.ini && \
    echo '; Blackfire PHP configuration' >> /etc/php/${PHP_VERSION}/cli/conf.d/92-blackfire-config.ini && \
    echo '; blackfire.agent_socket=unix:///tmp/agent.sock' >> /etc/php/${PHP_VERSION}/cli/conf.d/92-blackfire-config.ini && \
    cp /etc/php/${PHP_VERSION}/cli/conf.d/92-blackfire-config.ini /etc/php/${PHP_VERSION}/fpm/conf.d/92-blackfire-config.ini

# Blackfire setup script
RUN echo '#!/bin/bash' > /usr/local/bin/blackfire-setup && \
    echo 'echo "Setting up Blackfire..."' >> /usr/local/bin/blackfire-setup && \
    echo 'echo "Enter your Blackfire Server ID:"' >> /usr/local/bin/blackfire-setup && \
    echo 'read -r BLACKFIRE_SERVER_ID' >> /usr/local/bin/blackfire-setup && \
    echo 'echo "Enter your Blackfire Server Token:"' >> /usr/local/bin/blackfire-setup && \
    echo 'read -r BLACKFIRE_SERVER_TOKEN' >> /usr/local/bin/blackfire-setup && \
    echo 'echo "Enter your Blackfire Client ID:"' >> /usr/local/bin/blackfire-setup && \
    echo 'read -r BLACKFIRE_CLIENT_ID' >> /usr/local/bin/blackfire-setup && \
    echo 'echo "Enter your Blackfire Client Token:"' >> /usr/local/bin/blackfire-setup && \
    echo 'read -r BLACKFIRE_CLIENT_TOKEN' >> /usr/local/bin/blackfire-setup && \
    echo 'sudo sed -i "s/; server-id=/server-id=$BLACKFIRE_SERVER_ID/" /etc/blackfire/agent' >> /usr/local/bin/blackfire-setup && \
    echo 'sudo sed -i "s/; server-token=/server-token=$BLACKFIRE_SERVER_TOKEN/" /etc/blackfire/agent' >> /usr/local/bin/blackfire-setup && \
    echo 'blackfire config --client-id=$BLACKFIRE_CLIENT_ID --client-token=$BLACKFIRE_CLIENT_TOKEN' >> /usr/local/bin/blackfire-setup && \
    echo 'echo "Blackfire configured successfully!"' >> /usr/local/bin/blackfire-setup && \
    echo 'echo "Run: sudo systemctl restart blackfire-agent"' >> /usr/local/bin/blackfire-setup && \
    chmod +x /usr/local/bin/blackfire-setup

# Note: New Relic can be installed later if needed for performance monitoring
# Install manually if required:
# curl -L https://download.newrelic.com/php_agent/release/newrelic-php5-latest-linux.tar.gz | tar -C /tmp -zx
# NR_INSTALL_USE_CP_NOT_LN=1 NR_INSTALL_SILENT=1 /tmp/newrelic-php5-*/newrelic-install install

# Install RabbitMQ using the official Ubuntu repository (more reliable)
RUN apt-get update && \
    apt-get install -y rabbitmq-server && \
    rm -rf /var/lib/apt/lists/*

# Configure RabbitMQ for container environment
RUN mkdir -p /var/lib/rabbitmq /var/log/rabbitmq && \
    chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /var/log/rabbitmq && \
    chmod 755 /var/lib/rabbitmq /var/log/rabbitmq

# Enable RabbitMQ management plugin and configure
RUN rabbitmq-plugins enable rabbitmq_management

# RabbitMQ configuration for container environment
RUN echo '# RabbitMQ configuration for development' > /etc/rabbitmq/rabbitmq.conf && \
    echo 'loopback_users.guest = false' >> /etc/rabbitmq/rabbitmq.conf && \
    echo 'listeners.tcp.default = 5672' >> /etc/rabbitmq/rabbitmq.conf && \
    echo 'management.tcp.port = 15672' >> /etc/rabbitmq/rabbitmq.conf && \
    echo 'log.file.level = info' >> /etc/rabbitmq/rabbitmq.conf && \
    echo 'log.console = true' >> /etc/rabbitmq/rabbitmq.conf

# Improved RabbitMQ setup script (using service commands only)
RUN echo '#!/bin/bash' > /usr/local/bin/rabbitmq-setup && \
    echo 'echo "🐰 Setting up RabbitMQ..."' >> /usr/local/bin/rabbitmq-setup && \
    echo '' >> /usr/local/bin/rabbitmq-setup && \
    echo '# Ensure directories exist with correct permissions' >> /usr/local/bin/rabbitmq-setup && \
    echo 'sudo mkdir -p /var/lib/rabbitmq /var/log/rabbitmq' >> /usr/local/bin/rabbitmq-setup && \
    echo 'sudo chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /var/log/rabbitmq' >> /usr/local/bin/rabbitmq-setup && \
    echo '' >> /usr/local/bin/rabbitmq-setup && \
    echo '# Fix hostname issues that can prevent RabbitMQ startup' >> /usr/local/bin/rabbitmq-setup && \
    echo 'if ! grep -q "$(hostname)" /etc/hosts; then' >> /usr/local/bin/rabbitmq-setup && \
    echo '  echo "🔧 Adding hostname to /etc/hosts..."' >> /usr/local/bin/rabbitmq-setup && \
    echo '  echo "127.0.0.1 $(hostname)" | sudo tee -a /etc/hosts >/dev/null' >> /usr/local/bin/rabbitmq-setup && \
    echo 'fi' >> /usr/local/bin/rabbitmq-setup && \
    echo '' >> /usr/local/bin/rabbitmq-setup && \
    echo '# Start RabbitMQ with retry logic' >> /usr/local/bin/rabbitmq-setup && \
    echo 'echo "🚀 Starting RabbitMQ..."' >> /usr/local/bin/rabbitmq-setup && \
    echo 'for i in {1..3}; do' >> /usr/local/bin/rabbitmq-setup && \
    echo '  if sudo service rabbitmq-server start 2>/dev/null; then' >> /usr/local/bin/rabbitmq-setup && \
    echo '    echo "✅ RabbitMQ started (attempt $i)"' >> /usr/local/bin/rabbitmq-setup && \
    echo '    break' >> /usr/local/bin/rabbitmq-setup && \
    echo '  elif sudo rabbitmq-server -detached 2>/dev/null; then' >> /usr/local/bin/rabbitmq-setup && \
    echo '    echo "✅ RabbitMQ started with direct command (attempt $i)"' >> /usr/local/bin/rabbitmq-setup && \
    echo '    break' >> /usr/local/bin/rabbitmq-setup && \
    echo '  else' >> /usr/local/bin/rabbitmq-setup && \
    echo '    echo "⚠️  Attempt $i failed, retrying..."' >> /usr/local/bin/rabbitmq-setup && \
    echo '    sleep 2' >> /usr/local/bin/rabbitmq-setup && \
    echo '  fi' >> /usr/local/bin/rabbitmq-setup && \
    echo 'done' >> /usr/local/bin/rabbitmq-setup && \
    echo '' >> /usr/local/bin/rabbitmq-setup && \
    echo '# Wait for RabbitMQ to be ready' >> /usr/local/bin/rabbitmq-setup && \
    echo 'echo "⏳ Waiting for RabbitMQ to be ready..."' >> /usr/local/bin/rabbitmq-setup && \
    echo 'for i in {1..30}; do' >> /usr/local/bin/rabbitmq-setup && \
    echo '  if sudo rabbitmqctl status >/dev/null 2>&1; then' >> /usr/local/bin/rabbitmq-setup && \
    echo '    echo "✅ RabbitMQ is ready!"' >> /usr/local/bin/rabbitmq-setup && \
    echo '    break' >> /usr/local/bin/rabbitmq-setup && \
    echo '  fi' >> /usr/local/bin/rabbitmq-setup && \
    echo '  sleep 1' >> /usr/local/bin/rabbitmq-setup && \
    echo 'done' >> /usr/local/bin/rabbitmq-setup && \
    echo '' >> /usr/local/bin/rabbitmq-setup && \
    echo '# Configure users and permissions' >> /usr/local/bin/rabbitmq-setup && \
    echo 'echo "🔧 Configuring RabbitMQ users..."' >> /usr/local/bin/rabbitmq-setup && \
    echo 'sudo rabbitmqctl add_user admin admin 2>/dev/null || echo "User admin already exists"' >> /usr/local/bin/rabbitmq-setup && \
    echo 'sudo rabbitmqctl set_user_tags admin administrator' >> /usr/local/bin/rabbitmq-setup && \
    echo 'sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"' >> /usr/local/bin/rabbitmq-setup && \
    echo '' >> /usr/local/bin/rabbitmq-setup && \
    echo '# Enable guest user for development (optional)' >> /usr/local/bin/rabbitmq-setup && \
    echo 'sudo rabbitmqctl set_permissions -p / guest ".*" ".*" ".*" 2>/dev/null || true' >> /usr/local/bin/rabbitmq-setup && \
    echo '' >> /usr/local/bin/rabbitmq-setup && \
    echo 'echo "✅ RabbitMQ setup completed!"' >> /usr/local/bin/rabbitmq-setup && \
    echo 'echo "🌐 Management UI: http://localhost:15672"' >> /usr/local/bin/rabbitmq-setup && \
    echo 'echo "👤 Login: admin/admin or guest/guest"' >> /usr/local/bin/rabbitmq-setup && \
    chmod +x /usr/local/bin/rabbitmq-setup

# RabbitMQ diagnostic script (no systemctl as no systed support for ONA)
RUN echo '#!/bin/bash' > /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo "🐰 RabbitMQ Diagnostic"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo "===================="' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo "Service status:"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'sudo service rabbitmq-server status || echo "❌ Service not running"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo ""' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo "Process check:"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'ps aux | grep rabbit | grep -v grep || echo "❌ No RabbitMQ processes"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo ""' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo "Port check:"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'sudo netstat -tlnp | grep :5672 || echo "❌ Port 5672 not listening"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'sudo netstat -tlnp | grep :15672 || echo "❌ Port 15672 not listening"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo ""' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo "RabbitMQ status:"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'sudo rabbitmqctl status 2>/dev/null || echo "❌ RabbitMQ not responding to rabbitmqctl"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo ""' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo "Hostname check:"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'hostname' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'grep $(hostname) /etc/hosts || echo "⚠️  Hostname not in /etc/hosts"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo ""' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo "Log files:"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'sudo ls -la /var/log/rabbitmq/ 2>/dev/null || echo "❌ No log directory"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo ""' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'echo "Recent errors (last 10 lines):"' >> /usr/local/bin/rabbitmq-diagnose && \
    echo 'sudo find /var/log/rabbitmq -name "*.log" -exec tail -10 {} \; 2>/dev/null || echo "❌ No logs available"' >> /usr/local/bin/rabbitmq-diagnose && \
    chmod +x /usr/local/bin/rabbitmq-diagnose

# ==============================================
# CONFIGURATION FILES AND SCRIPTS
# ==============================================

# Create configuration directories
RUN mkdir -p /var/log/blackfire /var/run/blackfire /workspaces/magento2gitpod/var/log && \
    chown -R vscode:vscode /var/log/blackfire /var/run/blackfire /workspaces/magento2gitpod

# Modern MySQL configuration (use standard datadir initially)
RUN echo '[mysqld]' > /etc/mysql/conf.d/magento.cnf && \
    echo 'bind-address = 127.0.0.1' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'port = 3306' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'datadir = /var/lib/mysql' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'socket = /var/run/mysqld/mysqld.sock' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'pid-file = /var/run/mysqld/mysqld.pid' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'log-error = /var/log/mysql/error.log' >> /etc/mysql/conf.d/magento.cnf && \
    echo '' >> /etc/mysql/conf.d/magento.cnf && \
    echo '# Performance settings for Magento 2.4.8' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'innodb_buffer_pool_size = 2G' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'innodb_buffer_pool_instances = 8' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'innodb_log_file_size = 512M' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'innodb_log_buffer_size = 32M' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'innodb_flush_log_at_trx_commit = 2' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'innodb_file_per_table = 1' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'innodb_open_files = 400' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'innodb_io_capacity = 400' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'innodb_io_capacity_max = 2000' >> /etc/mysql/conf.d/magento.cnf && \
    echo '' >> /etc/mysql/conf.d/magento.cnf && \
    echo '# Connection settings' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'max_connections = 300' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'max_connect_errors = 1000000' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'wait_timeout = 28800' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'interactive_timeout = 28800' >> /etc/mysql/conf.d/magento.cnf && \
    echo '' >> /etc/mysql/conf.d/magento.cnf && \
    echo '# Temporary tables' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'max_heap_table_size = 128M' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'tmp_table_size = 128M' >> /etc/mysql/conf.d/magento.cnf && \
    echo '' >> /etc/mysql/conf.d/magento.cnf && \
    echo '# Other settings' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'sql_mode = ""' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'character-set-server = utf8mb4' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'collation-server = utf8mb4_unicode_ci' >> /etc/mysql/conf.d/magento.cnf && \
    echo '' >> /etc/mysql/conf.d/magento.cnf && \
    echo '[mysql]' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'default-character-set = utf8mb4' >> /etc/mysql/conf.d/magento.cnf && \
    echo '' >> /etc/mysql/conf.d/magento.cnf && \
    echo '[client]' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'default-character-set = utf8mb4' >> /etc/mysql/conf.d/magento.cnf && \
    echo 'socket = /var/run/mysqld/mysqld.sock' >> /etc/mysql/conf.d/magento.cnf

# Fix MariaDB socket directory and permissions, create persistent data directory
RUN mkdir -p /var/run/mysqld && \
    chown mysql:mysql /var/run/mysqld && \
    chmod 755 /var/run/mysqld && \
    mkdir -p /var/log/mysql && \
    chown mysql:mysql /var/log/mysql && \
    mkdir -p /workspaces/magento2gitpod/var/log && \
    chown vscode:vscode /workspaces/magento2gitpod/var/log

# .my.cnf for passwordless MySQL access
RUN echo '[client]' > /home/vscode/.my.cnf && \
    echo 'user=root' >> /home/vscode/.my.cnf && \
    echo 'password=nem4540' >> /home/vscode/.my.cnf && \
    echo 'socket=/var/run/mysqld/mysqld.sock' >> /home/vscode/.my.cnf && \
    echo 'default-character-set=utf8mb4' >> /home/vscode/.my.cnf && \
    chown vscode:vscode /home/vscode/.my.cnf && \
    chmod 600 /home/vscode/.my.cnf

# Skip MariaDB initialization during build - do it at runtime instead
RUN echo "MariaDB will be initialized at first startup"

# MariaDB setup script to handle unix_socket authentication
RUN echo '#!/bin/bash' > /usr/local/bin/setup-mysql-data && \
    echo 'echo "🔧 Setting up MariaDB..."' >> /usr/local/bin/setup-mysql-data && \
    echo '' >> /usr/local/bin/setup-mysql-data && \
    echo '# Check if MariaDB is running, if not start it' >> /usr/local/bin/setup-mysql-data && \
    echo 'if ! sudo service mariadb status >/dev/null 2>&1; then' >> /usr/local/bin/setup-mysql-data && \
    echo '  echo "🚀 Starting MariaDB..."' >> /usr/local/bin/setup-mysql-data && \
    echo '  sudo service mariadb start' >> /usr/local/bin/setup-mysql-data && \
    echo '  sleep 3' >> /usr/local/bin/setup-mysql-data && \
    echo 'fi' >> /usr/local/bin/setup-mysql-data && \
    echo '' >> /usr/local/bin/setup-mysql-data && \
    echo '# Configure password and database using sudo (unix_socket auth)' >> /usr/local/bin/setup-mysql-data && \
    echo 'echo "🔐 Configuring MariaDB authentication..."' >> /usr/local/bin/setup-mysql-data && \
    echo 'sudo mariadb -u root -e "' >> /usr/local/bin/setup-mysql-data && \
    echo '  ALTER USER root@localhost IDENTIFIED VIA mysql_native_password USING PASSWORD('"'"'nem4540'"'"');' >> /usr/local/bin/setup-mysql-data && \
    echo '  CREATE DATABASE IF NOT EXISTS magento2;' >> /usr/local/bin/setup-mysql-data && \
    echo '  GRANT ALL PRIVILEGES ON *.* TO root@localhost;' >> /usr/local/bin/setup-mysql-data && \
    echo '  FLUSH PRIVILEGES;' >> /usr/local/bin/setup-mysql-data && \
    echo '" 2>/dev/null || {' >> /usr/local/bin/setup-mysql-data && \
    echo '  echo "⚠️  Trying alternative method..."' >> /usr/local/bin/setup-mysql-data && \
    echo '  sudo mariadb -e "' >> /usr/local/bin/setup-mysql-data && \
    echo '    UPDATE mysql.user SET plugin='"'"'mysql_native_password'"'"', Password=PASSWORD('"'"'nem4540'"'"') WHERE User='"'"'root'"'"' AND Host='"'"'localhost'"'"';' >> /usr/local/bin/setup-mysql-data && \
    echo '    CREATE DATABASE IF NOT EXISTS magento2;' >> /usr/local/bin/setup-mysql-data && \
    echo '    FLUSH PRIVILEGES;' >> /usr/local/bin/setup-mysql-data && \
    echo '  " 2>/dev/null || echo "Could not set password via alternative method"' >> /usr/local/bin/setup-mysql-data && \
    echo '}' >> /usr/local/bin/setup-mysql-data && \
    echo '' >> /usr/local/bin/setup-mysql-data && \
    echo '# Test the connection' >> /usr/local/bin/setup-mysql-data && \
    echo 'echo "🔍 Testing connection..."' >> /usr/local/bin/setup-mysql-data && \
    echo 'if mariadb -u root -pnem4540 -e "SELECT '"'"'Connection successful!'"'"' AS Status;" 2>/dev/null; then' >> /usr/local/bin/setup-mysql-data && \
    echo '  echo "✅ MariaDB password authentication working!"' >> /usr/local/bin/setup-mysql-data && \
    echo 'else' >> /usr/local/bin/setup-mysql-data && \
    echo '  echo "⚠️  Password authentication failed, but unix_socket might work"' >> /usr/local/bin/setup-mysql-data && \
    echo '  echo "💡 Try: sudo mysql"' >> /usr/local/bin/setup-mysql-data && \
    echo 'fi' >> /usr/local/bin/setup-mysql-data && \
    echo '' >> /usr/local/bin/setup-mysql-data && \
    echo '# Create backup directory for future use' >> /usr/local/bin/setup-mysql-data && \
    echo 'if [ ! -d "/workspaces/magento2gitpod/mysql-backup" ]; then' >> /usr/local/bin/setup-mysql-data && \
    echo '  echo "📂 Creating backup of MySQL data..."' >> /usr/local/bin/setup-mysql-data && \
    echo '  mkdir -p /workspaces/magento2gitpod/mysql-backup' >> /usr/local/bin/setup-mysql-data && \
    echo '  sudo cp -r /var/lib/mysql/* /workspaces/magento2gitpod/mysql-backup/ 2>/dev/null || true' >> /usr/local/bin/setup-mysql-data && \
    echo '  echo "💡 MySQL data backed up to /workspaces/magento2gitpod/mysql-backup"' >> /usr/local/bin/setup-mysql-data && \
    echo 'fi' >> /usr/local/bin/setup-mysql-data && \
    echo '' >> /usr/local/bin/setup-mysql-data && \
    echo 'echo "✅ MariaDB setup completed"' >> /usr/local/bin/setup-mysql-data && \
    chmod +x /usr/local/bin/setup-mysql-data

# MariaDB connection test script
RUN echo '#!/bin/bash' > /usr/local/bin/test-mysql && \
    echo 'echo "🔍 Testing MariaDB connection..."' >> /usr/local/bin/test-mysql && \
    echo 'echo ""' >> /usr/local/bin/test-mysql && \
    echo '# Check if MariaDB service is running' >> /usr/local/bin/test-mysql && \
    echo 'if ! sudo service mariadb status >/dev/null 2>&1; then' >> /usr/local/bin/test-mysql && \
    echo '  echo "❌ MariaDB service is not running!"' >> /usr/local/bin/test-mysql && \
    echo '  echo "💡 Try: start-core (this will setup and start MariaDB)"' >> /usr/local/bin/test-mysql && \
    echo '  exit 1' >> /usr/local/bin/test-mysql && \
    echo 'fi' >> /usr/local/bin/test-mysql && \
    echo 'echo "✅ MariaDB service is running"' >> /usr/local/bin/test-mysql && \
    echo '' >> /usr/local/bin/test-mysql && \
    echo '# Test passwordless connection (.my.cnf)' >> /usr/local/bin/test-mysql && \
    echo 'echo "🔐 Testing passwordless connection..."' >> /usr/local/bin/test-mysql && \
    echo 'if mariadb -e "SELECT VERSION() AS MariaDB_Version, USER() AS Current_User;" 2>/dev/null; then' >> /usr/local/bin/test-mysql && \
    echo '  echo ""' >> /usr/local/bin/test-mysql && \
    echo '  echo "✅ Passwordless connection successful!"' >> /usr/local/bin/test-mysql && \
    echo '  echo ""' >> /usr/local/bin/test-mysql && \
    echo '  echo "📋 Connection Details:"' >> /usr/local/bin/test-mysql && \
    echo '  echo "  Config file: ~/.my.cnf"' >> /usr/local/bin/test-mysql && \
    echo '  echo "  Username: root"' >> /usr/local/bin/test-mysql && \
    echo '  echo "  Password: nem4540 (auto-configured)"' >> /usr/local/bin/test-mysql && \
    echo '  echo "  Socket: /var/run/mysqld/mysqld.sock"' >> /usr/local/bin/test-mysql && \
    echo '  echo ""' >> /usr/local/bin/test-mysql && \
    echo '  echo "💻 Usage:"' >> /usr/local/bin/test-mysql && \
    echo '  echo "  mysql                 # Connect to MariaDB"' >> /usr/local/bin/test-mysql && \
    echo '  echo "  mysql magento2        # Connect to magento2 database"' >> /usr/local/bin/test-mysql && \
    echo '  echo "  mysql -e \"SHOW DATABASES;\" # Quick queries"' >> /usr/local/bin/test-mysql && \
    echo '  echo ""' >> /usr/local/bin/test-mysql && \
    echo '  echo "🗄️ Available databases:"' >> /usr/local/bin/test-mysql && \
    echo '  mariadb -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema" || echo "  Could not list databases"' >> /usr/local/bin/test-mysql && \
    echo 'elif mariadb -u root -pnem4540 -e "SELECT VERSION() AS MariaDB_Version;" 2>/dev/null; then' >> /usr/local/bin/test-mysql && \
    echo '  echo "⚠️  Connection works with manual password"' >> /usr/local/bin/test-mysql && \
    echo '  echo "💡 .my.cnf might need updating"' >> /usr/local/bin/test-mysql && \
    echo 'else' >> /usr/local/bin/test-mysql && \
    echo '  echo "❌ Cannot connect to MariaDB!"' >> /usr/local/bin/test-mysql && \
    echo '  echo ""' >> /usr/local/bin/test-mysql && \
    echo '  echo "🔧 Troubleshooting:"' >> /usr/local/bin/test-mysql && \
    echo '  echo "1. Run: setup-mysql-data"' >> /usr/local/bin/test-mysql && \
    echo '  echo "2. Check service: sudo service mariadb status"' >> /usr/local/bin/test-mysql && \
    echo '  echo "3. Check socket: ls -la /var/run/mysqld/mysqld.sock"' >> /usr/local/bin/test-mysql && \
    echo '  echo "4. Check logs: sudo tail -f /var/log/mysql/error.log"' >> /usr/local/bin/test-mysql && \
    echo '  echo "5. Try restart: sudo service mariadb restart"' >> /usr/local/bin/test-mysql && \
    echo 'fi' >> /usr/local/bin/test-mysql && \
    chmod +x /usr/local/bin/test-mysql

# PHP-FPM pool configuration
RUN echo '[www]' > /etc/php/8.2/fpm/pool.d/www.conf && \
    echo 'user = vscode' >> /etc/php/8.2/fpm/pool.d/www.conf && \
    echo 'group = vscode' >> /etc/php/8.2/fpm/pool.d/www.conf && \
    echo 'listen = 127.0.0.1:9000' >> /etc/php/8.2/fpm/pool.d/www.conf && \
    echo 'listen.owner = vscode' >> /etc/php/8.2/fpm/pool.d/www.conf && \
    echo 'listen.group = vscode' >> /etc/php/8.2/fpm/pool.d/www.conf && \
    echo 'pm = dynamic' >> /etc/php/8.2/fpm/pool.d/www.conf && \
    echo 'pm.max_children = 20' >> /etc/php/8.2/fpm/pool.d/www.conf && \
    echo 'pm.start_servers = 3' >> /etc/php/8.2/fpm/pool.d/www.conf && \
    echo 'pm.min_spare_servers = 1' >> /etc/php/8.2/fpm/pool.d/www.conf && \
    echo 'pm.max_spare_servers = 10' >> /etc/php/8.2/fpm/pool.d/www.conf

# Nginx configuration to use TCP connection
RUN echo 'upstream fastcgi_backend {' > /etc/nginx/sites-available/magento && \
    echo '    server 127.0.0.1:9000;' >> /etc/nginx/sites-available/magento && \
    echo '}' >> /etc/nginx/sites-available/magento && \
    echo '' >> /etc/nginx/sites-available/magento && \
    echo 'server {' >> /etc/nginx/sites-available/magento && \
    echo '    listen 8002;' >> /etc/nginx/sites-available/magento && \
    echo '    server_name _;' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    set $MAGE_ROOT /workspaces/magento2gitpod;' >> /etc/nginx/sites-available/magento && \
    echo '    set $MAGE_DEBUG_SHOW_ARGS 0;' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    root $MAGE_ROOT/pub;' >> /etc/nginx/sites-available/magento && \
    echo '    index index.php;' >> /etc/nginx/sites-available/magento && \
    echo '    autoindex off;' >> /etc/nginx/sites-available/magento && \
    echo '    charset UTF-8;' >> /etc/nginx/sites-available/magento && \
    echo '    error_page 404 403 = /errors/404.php;' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    access_log /var/log/nginx/access.log;' >> /etc/nginx/sites-available/magento && \
    echo '    error_log /var/log/nginx/error.log;' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    # Deny access to sensitive files' >> /etc/nginx/sites-available/magento && \
    echo '    location /.user.ini {' >> /etc/nginx/sites-available/magento && \
    echo '        deny all;' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    # PHP entry point for setup application' >> /etc/nginx/sites-available/magento && \
    echo '    location ~* ^/setup($|/) {' >> /etc/nginx/sites-available/magento && \
    echo '        root $MAGE_ROOT;' >> /etc/nginx/sites-available/magento && \
    echo '        location ~ ^/setup/index.php {' >> /etc/nginx/sites-available/magento && \
    echo '            fastcgi_pass   fastcgi_backend;' >> /etc/nginx/sites-available/magento && \
    echo '            fastcgi_param  PHP_FLAG  "session.auto_start=off \\n suhosin.session.cryptua=off";' >> /etc/nginx/sites-available/magento && \
    echo '            fastcgi_param  PHP_VALUE "memory_limit=4G \\n max_execution_time=1800";' >> /etc/nginx/sites-available/magento && \
    echo '            fastcgi_read_timeout 600s;' >> /etc/nginx/sites-available/magento && \
    echo '            fastcgi_connect_timeout 600s;' >> /etc/nginx/sites-available/magento && \
    echo '            fastcgi_index  index.php;' >> /etc/nginx/sites-available/magento && \
    echo '            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;' >> /etc/nginx/sites-available/magento && \
    echo '            include        fastcgi_params;' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '        location ~ ^/setup/(?!pub/). {' >> /etc/nginx/sites-available/magento && \
    echo '            deny all;' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '        location ~ ^/setup/pub/ {' >> /etc/nginx/sites-available/magento && \
    echo '            add_header X-Frame-Options "SAMEORIGIN";' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    # PHP entry point for update application' >> /etc/nginx/sites-available/magento && \
    echo '    location ~* ^/update($|/) {' >> /etc/nginx/sites-available/magento && \
    echo '        root $MAGE_ROOT;' >> /etc/nginx/sites-available/magento && \
    echo '        location ~ ^/update/index.php {' >> /etc/nginx/sites-available/magento && \
    echo '            fastcgi_split_path_info ^(/update/index.php)(/.+)$;' >> /etc/nginx/sites-available/magento && \
    echo '            fastcgi_pass   fastcgi_backend;' >> /etc/nginx/sites-available/magento && \
    echo '            fastcgi_index  index.php;' >> /etc/nginx/sites-available/magento && \
    echo '            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;' >> /etc/nginx/sites-available/magento && \
    echo '            fastcgi_param  PATH_INFO        $fastcgi_path_info;' >> /etc/nginx/sites-available/magento && \
    echo '            include        fastcgi_params;' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '        location ~ ^/update/(?!pub/). {' >> /etc/nginx/sites-available/magento && \
    echo '            deny all;' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '        location ~ ^/update/pub/ {' >> /etc/nginx/sites-available/magento && \
    echo '            add_header X-Frame-Options "SAMEORIGIN";' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    location / {' >> /etc/nginx/sites-available/magento && \
    echo '        try_files $uri $uri/ /index.php$is_args$args;' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    location /pub/ {' >> /etc/nginx/sites-available/magento && \
    echo '        location ~ ^/pub/media/(downloadable|customer|import|custom_options|theme_customization/.*\\.xml) {' >> /etc/nginx/sites-available/magento && \
    echo '            deny all;' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '        alias $MAGE_ROOT/pub/;' >> /etc/nginx/sites-available/magento && \
    echo '        add_header X-Frame-Options "SAMEORIGIN";' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    location /static/ {' >> /etc/nginx/sites-available/magento && \
    echo '        location ~ ^/static/version\\d*/ {' >> /etc/nginx/sites-available/magento && \
    echo '            rewrite ^/static/version\\d*/(.*)$ /static/$1 last;' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '        location ~* \\.(ico|jpg|jpeg|png|gif|svg|svgz|webp|avif|avifs|js|css|eot|ttf|otf|woff|woff2|html|json|webmanifest)$ {' >> /etc/nginx/sites-available/magento && \
    echo '            add_header Cache-Control "public, max-age=31536000, immutable";' >> /etc/nginx/sites-available/magento && \
    echo '            add_header X-Frame-Options "SAMEORIGIN";' >> /etc/nginx/sites-available/magento && \
    echo '            if (!-f $request_filename) {' >> /etc/nginx/sites-available/magento && \
    echo '                rewrite ^/static/(version\\d*/)?(.*)$ /static.php?resource=$2 last;' >> /etc/nginx/sites-available/magento && \
    echo '            }' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '        location ~* \\.(zip|gz|gzip|bz2|csv|xml)$ {' >> /etc/nginx/sites-available/magento && \
    echo '            add_header Cache-Control "no-store";' >> /etc/nginx/sites-available/magento && \
    echo '            add_header X-Frame-Options "SAMEORIGIN";' >> /etc/nginx/sites-available/magento && \
    echo '            expires    off;' >> /etc/nginx/sites-available/magento && \
    echo '            if (!-f $request_filename) {' >> /etc/nginx/sites-available/magento && \
    echo '               rewrite ^/static/(version\\d*/)?(.*)$ /static.php?resource=$2 last;' >> /etc/nginx/sites-available/magento && \
    echo '            }' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '        if (!-f $request_filename) {' >> /etc/nginx/sites-available/magento && \
    echo '            rewrite ^/static/(version\\d*/)?(.*)$ /static.php?resource=$2 last;' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '        add_header X-Frame-Options "SAMEORIGIN";' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    location /media/ {' >> /etc/nginx/sites-available/magento && \
    echo '        try_files $uri $uri/ /get.php$is_args$args;' >> /etc/nginx/sites-available/magento && \
    echo '        location ~ ^/media/theme_customization/.*\\.xml {' >> /etc/nginx/sites-available/magento && \
    echo '            deny all;' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '        location ~* \\.(ico|jpg|jpeg|png|gif|svg|svgz|webp|avif|avifs|js|css|eot|ttf|otf|woff|woff2)$ {' >> /etc/nginx/sites-available/magento && \
    echo '            add_header Cache-Control "public";' >> /etc/nginx/sites-available/magento && \
    echo '            add_header X-Frame-Options "SAMEORIGIN";' >> /etc/nginx/sites-available/magento && \
    echo '            expires +1y;' >> /etc/nginx/sites-available/magento && \
    echo '            try_files $uri $uri/ /get.php$is_args$args;' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '        location ~* \\.(zip|gz|gzip|bz2|csv|xml)$ {' >> /etc/nginx/sites-available/magento && \
    echo '            add_header Cache-Control "no-store";' >> /etc/nginx/sites-available/magento && \
    echo '            add_header X-Frame-Options "SAMEORIGIN";' >> /etc/nginx/sites-available/magento && \
    echo '            expires    off;' >> /etc/nginx/sites-available/magento && \
    echo '            try_files $uri $uri/ /get.php$is_args$args;' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '        add_header X-Frame-Options "SAMEORIGIN";' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    location /media/customer/ {' >> /etc/nginx/sites-available/magento && \
    echo '        deny all;' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    location /media/downloadable/ {' >> /etc/nginx/sites-available/magento && \
    echo '        deny all;' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    location /media/import/ {' >> /etc/nginx/sites-available/magento && \
    echo '        deny all;' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    location /media/custom_options/ {' >> /etc/nginx/sites-available/magento && \
    echo '        deny all;' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    location /errors/ {' >> /etc/nginx/sites-available/magento && \
    echo '        location ~* \\.xml$ {' >> /etc/nginx/sites-available/magento && \
    echo '            deny all;' >> /etc/nginx/sites-available/magento && \
    echo '        }' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    # PHP entry point for main application' >> /etc/nginx/sites-available/magento && \
    echo '    location ~ ^/(index|get|static|errors/report|errors/404|errors/503|health_check)\\.php$ {' >> /etc/nginx/sites-available/magento && \
    echo '        try_files $uri =404;' >> /etc/nginx/sites-available/magento && \
    echo '        fastcgi_pass   fastcgi_backend;' >> /etc/nginx/sites-available/magento && \
    echo '        fastcgi_buffers 16 16k;' >> /etc/nginx/sites-available/magento && \
    echo '        fastcgi_buffer_size 32k;' >> /etc/nginx/sites-available/magento && \
    echo '        fastcgi_param  PHP_FLAG  "session.auto_start=off \\n suhosin.session.cryptua=off";' >> /etc/nginx/sites-available/magento && \
    echo '        fastcgi_param  PHP_VALUE "memory_limit=4G \\n max_execution_time=1800";' >> /etc/nginx/sites-available/magento && \
    echo '        fastcgi_read_timeout 600s;' >> /etc/nginx/sites-available/magento && \
    echo '        fastcgi_connect_timeout 600s;' >> /etc/nginx/sites-available/magento && \
    echo '        fastcgi_index  index.php;' >> /etc/nginx/sites-available/magento && \
    echo '        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;' >> /etc/nginx/sites-available/magento && \
    echo '        include        fastcgi_params;' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    # Gzip compression' >> /etc/nginx/sites-available/magento && \
    echo '    gzip on;' >> /etc/nginx/sites-available/magento && \
    echo '    gzip_disable "msie6";' >> /etc/nginx/sites-available/magento && \
    echo '    gzip_comp_level 6;' >> /etc/nginx/sites-available/magento && \
    echo '    gzip_min_length 1100;' >> /etc/nginx/sites-available/magento && \
    echo '    gzip_buffers 16 8k;' >> /etc/nginx/sites-available/magento && \
    echo '    gzip_proxied any;' >> /etc/nginx/sites-available/magento && \
    echo '    gzip_types' >> /etc/nginx/sites-available/magento && \
    echo '        text/plain' >> /etc/nginx/sites-available/magento && \
    echo '        text/css' >> /etc/nginx/sites-available/magento && \
    echo '        text/js' >> /etc/nginx/sites-available/magento && \
    echo '        text/xml' >> /etc/nginx/sites-available/magento && \
    echo '        text/javascript' >> /etc/nginx/sites-available/magento && \
    echo '        application/javascript' >> /etc/nginx/sites-available/magento && \
    echo '        application/x-javascript' >> /etc/nginx/sites-available/magento && \
    echo '        application/json' >> /etc/nginx/sites-available/magento && \
    echo '        application/xml' >> /etc/nginx/sites-available/magento && \
    echo '        application/xml+rss' >> /etc/nginx/sites-available/magento && \
    echo '        image/svg+xml;' >> /etc/nginx/sites-available/magento && \
    echo '    gzip_vary on;' >> /etc/nginx/sites-available/magento && \
    echo '    ' >> /etc/nginx/sites-available/magento && \
    echo '    # Banned locations' >> /etc/nginx/sites-available/magento && \
    echo '    location ~* (\\.php$|\\.phtml$|\\.htaccess$|\\.htpasswd$|\\.git) {' >> /etc/nginx/sites-available/magento && \
    echo '        deny all;' >> /etc/nginx/sites-available/magento && \
    echo '    }' >> /etc/nginx/sites-available/magento && \
    echo '}' >> /etc/nginx/sites-available/magento

# Magento permissions script for vscode user
RUN echo '#!/bin/bash' > /usr/local/bin/fix-magento-permissions && \
    echo 'echo "Setting Magento file permissions for vscode user..."' >> /usr/local/bin/fix-magento-permissions && \
    echo 'cd /workspaces/magento2gitpod' >> /usr/local/bin/fix-magento-permissions && \
    echo '# Set ownership to vscode:vscode' >> /usr/local/bin/fix-magento-permissions && \
    echo 'sudo chown -R vscode:vscode /workspaces/magento2gitpod' >> /usr/local/bin/fix-magento-permissions && \
    echo '# Set directory permissions to 755' >> /usr/local/bin/fix-magento-permissions && \
    echo 'find /workspaces/magento2gitpod -type d -exec chmod 755 {} \\;' >> /usr/local/bin/fix-magento-permissions && \
    echo '# Set file permissions to 644' >> /usr/local/bin/fix-magento-permissions && \
    echo 'find /workspaces/magento2gitpod -type f -exec chmod 644 {} \\;' >> /usr/local/bin/fix-magento-permissions && \
    echo '# Make specific files executable' >> /usr/local/bin/fix-magento-permissions && \
    echo 'chmod +x /workspaces/magento2gitpod/bin/magento' >> /usr/local/bin/fix-magento-permissions && \
    echo 'chmod +x /workspaces/magento2gitpod/m2-install.sh' >> /usr/local/bin/fix-magento-permissions && \
    echo 'chmod +x /workspaces/magento2gitpod/m2-install-solo.sh' >> /usr/local/bin/fix-magento-permissions && \
    echo '# Set writable permissions for var, generated, pub directories' >> /usr/local/bin/fix-magento-permissions && \
    echo 'chmod -R 775 /workspaces/magento2gitpod/var 2>/dev/null || true' >> /usr/local/bin/fix-magento-permissions && \
    echo 'chmod -R 775 /workspaces/magento2gitpod/generated 2>/dev/null || true' >> /usr/local/bin/fix-magento-permissions && \
    echo 'chmod -R 775 /workspaces/magento2gitpod/pub/static 2>/dev/null || true' >> /usr/local/bin/fix-magento-permissions && \
    echo 'chmod -R 775 /workspaces/magento2gitpod/pub/media 2>/dev/null || true' >> /usr/local/bin/fix-magento-permissions && \
    echo 'chmod -R 775 /workspaces/magento2gitpod/app/etc 2>/dev/null || true' >> /usr/local/bin/fix-magento-permissions && \
    echo 'echo "Magento permissions fixed!"' >> /usr/local/bin/fix-magento-permissions && \
    chmod +x /usr/local/bin/fix-magento-permissions

# Enable the site
RUN ln -sf /etc/nginx/sites-available/magento /etc/nginx/sites-enabled/default

# Helpful scripts
RUN echo '#!/bin/bash' > /usr/local/bin/magento-xdebug-enable && \
    echo 'mv /etc/php/8.2/cli/conf.d/20-xdebug.ini.disabled /etc/php/8.2/cli/conf.d/20-xdebug.ini 2>/dev/null || true' >> /usr/local/bin/magento-xdebug-enable && \
    echo 'mv /etc/php/8.2/fpm/conf.d/20-xdebug.ini.disabled /etc/php/8.2/fpm/conf.d/20-xdebug.ini 2>/dev/null || true' >> /usr/local/bin/magento-xdebug-enable && \
    echo 'systemctl reload php8.2-fpm 2>/dev/null || service php8.2-fpm reload 2>/dev/null || true' >> /usr/local/bin/magento-xdebug-enable && \
    echo 'echo "Xdebug enabled!"' >> /usr/local/bin/magento-xdebug-enable

RUN echo '#!/bin/bash' > /usr/local/bin/magento-xdebug-disable && \
    echo 'mv /etc/php/8.2/cli/conf.d/20-xdebug.ini /etc/php/8.2/cli/conf.d/20-xdebug.ini.disabled 2>/dev/null || true' >> /usr/local/bin/magento-xdebug-disable && \
    echo 'mv /etc/php/8.2/fpm/conf.d/20-xdebug.ini /etc/php/8.2/fpm/conf.d/20-xdebug.ini.disabled 2>/dev/null || true' >> /usr/local/bin/magento-xdebug-disable && \
    echo 'systemctl reload php8.2-fpm 2>/dev/null || service php8.2-fpm reload 2>/dev/null || true' >> /usr/local/bin/magento-xdebug-disable && \
    echo 'echo "Xdebug disabled!"' >> /usr/local/bin/magento-xdebug-disable

# Version information script
RUN echo '#!/bin/bash' > /usr/local/bin/magento-versions && \
    echo 'echo "=== Magento 2.4.8 Development Environment ==="' >> /usr/local/bin/magento-versions && \
    echo 'echo "PHP Version: $(php --version | head -n1)"' >> /usr/local/bin/magento-versions && \
    echo 'echo "MariaDB Version: $(mariadb --version 2>/dev/null || mysql --version)"' >> /usr/local/bin/magento-versions && \
    echo 'echo "Composer Version: $(composer --version)"' >> /usr/local/bin/magento-versions && \
    echo 'echo "Node.js Version: $(node --version 2>/dev/null || echo "Not available")"' >> /usr/local/bin/magento-versions && \
    echo 'echo "NPM Version: $(npm --version 2>/dev/null || echo "Not available")"' >> /usr/local/bin/magento-versions && \
    echo 'echo "Elasticsearch: 8.11.4"' >> /usr/local/bin/magento-versions && \
    echo 'echo "Redis: $(redis-server --version 2>/dev/null | head -n1 || echo "Not available")"' >> /usr/local/bin/magento-versions && \
    echo 'echo "RabbitMQ: $(rabbitmqctl version 2>/dev/null || echo "Not started")"' >> /usr/local/bin/magento-versions && \
    echo 'echo "Nginx: $(nginx -v 2>&1 | head -n1)"' >> /usr/local/bin/magento-versions && \
    echo 'echo "Blackfire: $(blackfire version 2>/dev/null | head -n1 || echo "Not configured")"' >> /usr/local/bin/magento-versions && \
    echo 'echo "New Relic: $(php --ri newrelic 2>/dev/null | grep "version" | head -n1 || echo "Not installed - run: newrelic-install")"' >> /usr/local/bin/magento-versions && \
    echo 'echo "=============================================="' >> /usr/local/bin/magento-versions && \
    echo 'echo "🚀 Service Management:"' >> /usr/local/bin/magento-versions && \
    echo 'echo "  start-all         - Start all services"' >> /usr/local/bin/magento-versions && \
    echo 'echo "  stop-all          - Stop all services"' >> /usr/local/bin/magento-versions && \
    echo 'echo "  restart-all       - Restart all services"' >> /usr/local/bin/magento-versions && \
    echo 'echo "  status-all        - Check service status"' >> /usr/local/bin/magento-versions && \
    echo 'echo ""' >> /usr/local/bin/magento-versions && \
    echo 'echo "🔧 Configuration:"' >> /usr/local/bin/magento-versions && \
    echo 'echo "  blackfire-config  - Configure Blackfire monitoring"' >> /usr/local/bin/magento-versions && \
    echo 'echo "  newrelic-install  - Install New Relic monitoring"' >> /usr/local/bin/magento-versions && \
    echo 'echo "  rabbitmq-config   - Setup RabbitMQ users and permissions"' >> /usr/local/bin/magento-versions && \
    echo 'echo "  xdebug-on/off     - Toggle Xdebug for debugging"' >> /usr/local/bin/magento-versions && \
    echo 'echo "=============================================="' >> /usr/local/bin/magento-versions

RUN chmod +x /usr/local/bin/magento-xdebug-enable /usr/local/bin/magento-xdebug-disable /usr/local/bin/magento-versions

# A quick fix script for MariaDB authentication
RUN echo '#!/bin/bash' > /usr/local/bin/fix-mysql-auth && \
    echo 'echo "🔧 Fixing MariaDB authentication..."' >> /usr/local/bin/fix-mysql-auth && \
    echo 'echo "This fixes the unix_socket authentication issue in MariaDB 10.6"' >> /usr/local/bin/fix-mysql-auth && \
    echo 'echo ""' >> /usr/local/bin/fix-mysql-auth && \
    echo 'sudo mariadb -e "' >> /usr/local/bin/fix-mysql-auth && \
    echo '  ALTER USER root@localhost IDENTIFIED VIA mysql_native_password USING PASSWORD('"'"'nem4540'"'"');' >> /usr/local/bin/fix-mysql-auth && \
    echo '  CREATE DATABASE IF NOT EXISTS magento2;' >> /usr/local/bin/fix-mysql-auth && \
    echo '  GRANT ALL PRIVILEGES ON *.* TO root@localhost;' >> /usr/local/bin/fix-mysql-auth && \
    echo '  FLUSH PRIVILEGES;' >> /usr/local/bin/fix-mysql-auth && \
    echo '" && echo "✅ MariaDB authentication fixed!" || echo "❌ Fix failed"' >> /usr/local/bin/fix-mysql-auth && \
    echo '' >> /usr/local/bin/fix-mysql-auth && \
    echo 'echo "🔍 Testing connection..."' >> /usr/local/bin/fix-mysql-auth && \
    echo 'if mariadb -u root -pnem4540 -e "SELECT '"'"'Success!'"'"' AS Status;"; then' >> /usr/local/bin/fix-mysql-auth && \
    echo '  echo "🎉 You can now use: mysql"' >> /usr/local/bin/fix-mysql-auth && \
    echo 'else' >> /usr/local/bin/fix-mysql-auth && \
    echo '  echo "❌ Still having issues. Try: sudo mysql"' >> /usr/local/bin/fix-mysql-auth && \
    echo 'fi' >> /usr/local/bin/fix-mysql-auth && \
    chmod +x /usr/local/bin/fix-mysql-auth

# Service management script
RUN echo '#!/bin/bash' > /usr/local/bin/magento-services && \
    echo 'case "$1" in' >> /usr/local/bin/magento-services && \
    echo '  start)' >> /usr/local/bin/magento-services && \
    echo '    echo "Starting Magento 2 services..."' >> /usr/local/bin/magento-services && \
    echo '    /usr/local/bin/setup-mysql-data' >> /usr/local/bin/magento-services && \
    echo '    sudo service mariadb start && echo "✅ MariaDB started" || echo "❌ MariaDB failed"' >> /usr/local/bin/magento-services && \
    echo '    sudo service redis-server start && echo "✅ Redis started" || echo "❌ Redis failed"' >> /usr/local/bin/magento-services && \
    echo '    sudo service php8.2-fpm start && echo "✅ PHP-FPM started" || echo "❌ PHP-FPM failed"' >> /usr/local/bin/magento-services && \
    echo '    sudo service nginx start && echo "✅ Nginx started" || echo "❌ Nginx failed"' >> /usr/local/bin/magento-services && \
    echo '    echo "Starting Elasticsearch..."' >> /usr/local/bin/magento-services && \
    echo '    if [ -d "$ES_HOME" ]; then' >> /usr/local/bin/magento-services && \
    echo '      export ES_JAVA_OPTS="-Xms512m -Xmx512m" && cd "$ES_HOME" && nohup ./bin/elasticsearch -E discovery.type=single-node -E network.host=0.0.0.0 -E http.port=9200 -E cluster.name=magento -E node.name=magento-node -E bootstrap.memory_lock=false -E xpack.security.enabled=false -E xpack.security.http.ssl.enabled=false -E xpack.security.transport.ssl.enabled=false > /tmp/elasticsearch.log 2>&1 & echo $! > ./pid' >> /usr/local/bin/magento-services && \
    echo '      sleep 40 && if curl -s http://localhost:9200 >/dev/null 2>&1; then echo "✅ Elasticsearch ${ELASTICSEARCH_VERSION} started successfully"; else echo "❌ Elasticsearch startup failed, check /tmp/elasticsearch.log"; fi' >> /usr/local/bin/magento-services && \
    echo '    else' >> /usr/local/bin/magento-services && \
    echo '      echo "⚠️  Elasticsearch not found at $ES_HOME"' >> /usr/local/bin/magento-services && \
    echo '    fi' >> /usr/local/bin/magento-services && \
    echo '    echo "Starting RabbitMQ (this may take a moment)..."' >> /usr/local/bin/magento-services && \
    echo '    /usr/local/bin/rabbitmq-setup && echo "✅ RabbitMQ started and configured" || echo "⚠️  RabbitMQ setup failed"' >> /usr/local/bin/magento-services && \
    echo '    echo ""' >> /usr/local/bin/magento-services && \
    echo '    echo "🎉 All services started!"' >> /usr/local/bin/magento-services && \
    echo '    echo "🔍 Run: test-db to verify database connection"' >> /usr/local/bin/magento-services && \
    echo '    echo "🌐 Web server should be available on port 8002"' >> /usr/local/bin/magento-services && \
    echo '    echo "🔎 Elasticsearch should be available on port 9200"' >> /usr/local/bin/magento-services && \
    echo '    ;;' >> /usr/local/bin/magento-services && \
    echo '  stop)' >> /usr/local/bin/magento-services && \
    echo '    echo "Stopping Magento 2 services..."' >> /usr/local/bin/magento-services && \
    echo '    sudo service rabbitmq-server stop 2>/dev/null && echo "🛑 RabbitMQ stopped" || echo "⚠️  RabbitMQ was not running"' >> /usr/local/bin/magento-services && \
    echo '    # Stop Elasticsearch' >> /usr/local/bin/magento-services && \
    echo '    if [ -f "$ES_HOME/pid" ]; then' >> /usr/local/bin/magento-services && \
    echo '      kill $(cat "$ES_HOME/pid") 2>/dev/null && echo "🛑 Elasticsearch stopped" || echo "⚠️  Elasticsearch PID not found"' >> /usr/local/bin/magento-services && \
    echo '      rm -f "$ES_HOME/pid"' >> /usr/local/bin/magento-services && \
    echo '    else' >> /usr/local/bin/magento-services && \
    echo '      pkill -f elasticsearch && echo "🛑 Elasticsearch stopped" || echo "⚠️  Elasticsearch was not running"' >> /usr/local/bin/magento-services && \
    echo '    fi' >> /usr/local/bin/magento-services && \
    echo '    sudo service nginx stop && echo "🛑 Nginx stopped"' >> /usr/local/bin/magento-services && \
    echo '    sudo service php8.2-fpm stop && echo "🛑 PHP-FPM stopped"' >> /usr/local/bin/magento-services && \
    echo '    sudo service redis-server stop && echo "🛑 Redis stopped"' >> /usr/local/bin/magento-services && \
    echo '    sudo service mariadb stop && echo "🛑 MariaDB stopped"' >> /usr/local/bin/magento-services && \
    echo '    echo "🎉 All services stopped!"' >> /usr/local/bin/magento-services && \
    echo '    ;;' >> /usr/local/bin/magento-services && \
    echo '  restart)' >> /usr/local/bin/magento-services && \
    echo '    echo "Restarting Magento 2 services..."' >> /usr/local/bin/magento-services && \
    echo '    $0 stop' >> /usr/local/bin/magento-services && \
    echo '    sleep 5' >> /usr/local/bin/magento-services && \
    echo '    $0 start' >> /usr/local/bin/magento-services && \
    echo '    ;;' >> /usr/local/bin/magento-services && \
    echo '  status)' >> /usr/local/bin/magento-services && \
    echo '    echo "=== Service Status ==="' >> /usr/local/bin/magento-services && \
    echo '    if sudo service mariadb status >/dev/null 2>&1; then echo "✅ MariaDB: Running"; else echo "❌ MariaDB: Stopped"; fi' >> /usr/local/bin/magento-services && \
    echo '    if sudo service redis-server status >/dev/null 2>&1; then echo "✅ Redis: Running"; else echo "❌ Redis: Stopped"; fi' >> /usr/local/bin/magento-services && \
    echo '    if sudo service php8.2-fpm status >/dev/null 2>&1; then echo "✅ PHP-FPM: Running"; else echo "❌ PHP-FPM: Stopped"; fi' >> /usr/local/bin/magento-services && \
    echo '    if sudo service nginx status >/dev/null 2>&1; then echo "✅ Nginx: Running"; else echo "❌ Nginx: Stopped"; fi' >> /usr/local/bin/magento-services && \
    echo '    # Check Elasticsearch status' >> /usr/local/bin/magento-services && \
    echo '    if curl -s http://localhost:9200 >/dev/null 2>&1; then echo "✅ Elasticsearch: Running"; else echo "❌ Elasticsearch: Stopped"; fi' >> /usr/local/bin/magento-services && \
    echo '    if sudo service rabbitmq-server status >/dev/null 2>&1; then echo "✅ RabbitMQ: Running"; else echo "❌ RabbitMQ: Stopped"; fi' >> /usr/local/bin/magento-services && \
    echo '    echo ""' >> /usr/local/bin/magento-services && \
    echo '    echo "📂 Data directories:"' >> /usr/local/bin/magento-services && \
    echo '    echo "  MySQL: /workspaces/magento2gitpod/mysql"' >> /usr/local/bin/magento-services && \
    echo '    echo "  Logs: /workspaces/magento2gitpod/var/log"' >> /usr/local/bin/magento-services && \
    echo '    echo "  Elasticsearch: $ES_HOME"' >> /usr/local/bin/magento-services && \
    echo '    echo ""' >> /usr/local/bin/magento-services && \
    echo '    echo "🔍 Service URLs:"' >> /usr/local/bin/magento-services && \
    echo '    echo "  Elasticsearch: http://localhost:9200"' >> /usr/local/bin/magento-services && \
    echo '    echo "  RabbitMQ Management: http://localhost:15672"' >> /usr/local/bin/magento-services && \
    echo '    echo ""' >> /usr/local/bin/magento-services && \
    echo '    echo "🔍 Run: test-db to check database connectivity"' >> /usr/local/bin/magento-services && \
    echo '    ;;' >> /usr/local/bin/magento-services && \
    echo '  start-quick)' >> /usr/local/bin/magento-services && \
    echo '    echo "Starting core services (skip RabbitMQ and Elasticsearch)..."' >> /usr/local/bin/magento-services && \
    echo '    /usr/local/bin/setup-mysql-data' >> /usr/local/bin/magento-services && \
    echo '    sudo service mariadb start && echo "✅ MariaDB started"' >> /usr/local/bin/magento-services && \
    echo '    sudo service redis-server start && echo "✅ Redis started"' >> /usr/local/bin/magento-services && \
    echo '    sudo service php8.2-fpm start && echo "✅ PHP-FPM started"' >> /usr/local/bin/magento-services && \
    echo '    sudo service nginx start && echo "✅ Nginx started"' >> /usr/local/bin/magento-services && \
    echo '    echo "🚀 Core services ready! Start Elasticsearch and RabbitMQ manually if needed."' >> /usr/local/bin/magento-services && \
    echo '    echo "💡 To start Elasticsearch: services elasticsearch start"' >> /usr/local/bin/magento-services && \
    echo '    echo "💡 To start RabbitMQ: rabbitmq-setup"' >> /usr/local/bin/magento-services && \
    echo '    ;;' >> /usr/local/bin/magento-services && \
    echo '  elasticsearch)' >> /usr/local/bin/magento-services && \
    echo '    case "$2" in' >> /usr/local/bin/magento-services && \
    echo '      start)' >> /usr/local/bin/magento-services && \
    echo '        if [ -d "$ES_HOME" ]; then' >> /usr/local/bin/magento-services && \
    echo '          export ES_JAVA_OPTS="-Xms512m -Xmx512m" && cd "$ES_HOME" && nohup ./bin/elasticsearch -E discovery.type=single-node -E network.host=0.0.0.0 -E http.port=9200 -E cluster.name=magento -E node.name=magento-node -E bootstrap.memory_lock=false -E xpack.security.enabled=false -E xpack.security.http.ssl.enabled=false -E xpack.security.transport.ssl.enabled=false > /tmp/elasticsearch.log 2>&1 & echo $! > ./pid' >> /usr/local/bin/magento-services && \
    echo '          sleep 20 && if curl -s http://localhost:9200 >/dev/null 2>&1; then echo "✅ Elasticsearch ${ELASTICSEARCH_VERSION} started successfully"; else echo "❌ Elasticsearch startup failed, check /tmp/elasticsearch.log"; fi' >> /usr/local/bin/magento-services && \
    echo '        else' >> /usr/local/bin/magento-services && \
    echo '          echo "❌ Elasticsearch not found at $ES_HOME"' >> /usr/local/bin/magento-services && \
    echo '        fi' >> /usr/local/bin/magento-services && \
    echo '        ;;' >> /usr/local/bin/magento-services && \
    echo '      stop)' >> /usr/local/bin/magento-services && \
    echo '        if [ -f "$ES_HOME/pid" ]; then' >> /usr/local/bin/magento-services && \
    echo '          kill $(cat "$ES_HOME/pid") 2>/dev/null && echo "🛑 Elasticsearch stopped"' >> /usr/local/bin/magento-services && \
    echo '          rm -f "$ES_HOME/pid"' >> /usr/local/bin/magento-services && \
    echo '        else' >> /usr/local/bin/magento-services && \
    echo '          pkill -f elasticsearch && echo "🛑 Elasticsearch stopped" || echo "⚠️  Elasticsearch was not running"' >> /usr/local/bin/magento-services && \
    echo '        fi' >> /usr/local/bin/magento-services && \
    echo '        ;;' >> /usr/local/bin/magento-services && \
    echo '      status)' >> /usr/local/bin/magento-services && \
    echo '        if curl -s http://localhost:9200 >/dev/null 2>&1; then' >> /usr/local/bin/magento-services && \
    echo '          echo "✅ Elasticsearch is running"' >> /usr/local/bin/magento-services && \
    echo '          curl -s http://localhost:9200 | jq . 2>/dev/null || curl -s http://localhost:9200' >> /usr/local/bin/magento-services && \
    echo '        else' >> /usr/local/bin/magento-services && \
    echo '          echo "❌ Elasticsearch is not running"' >> /usr/local/bin/magento-services && \
    echo '        fi' >> /usr/local/bin/magento-services && \
    echo '        ;;' >> /usr/local/bin/magento-services && \
    echo '      *)' >> /usr/local/bin/magento-services && \
    echo '        echo "Usage: $0 elasticsearch {start|stop|status}"' >> /usr/local/bin/magento-services && \
    echo '        ;;' >> /usr/local/bin/magento-services && \
    echo '    esac' >> /usr/local/bin/magento-services && \
    echo '    ;;' >> /usr/local/bin/magento-services && \
    echo '  *)' >> /usr/local/bin/magento-services && \
    echo '    echo "Usage: $0 {start|stop|restart|status|start-quick|elasticsearch}"' >> /usr/local/bin/magento-services && \
    echo '    echo ""' >> /usr/local/bin/magento-services && \
    echo '    echo "Commands:"' >> /usr/local/bin/magento-services && \
    echo '    echo "  start         # Start all services (including RabbitMQ and Elasticsearch)"' >> /usr/local/bin/magento-services && \
    echo '    echo "  start-quick   # Start core services (skip RabbitMQ and Elasticsearch)"' >> /usr/local/bin/magento-services && \
    echo '    echo "  status        # Check service status"' >> /usr/local/bin/magento-services && \
    echo '    echo "  elasticsearch # Manage Elasticsearch (start|stop|status)"' >> /usr/local/bin/magento-services && \
    echo '    echo "  test-db       # Test database connection"' >> /usr/local/bin/magento-services && \
    echo '    echo ""' >> /usr/local/bin/magento-services && \
    echo '    echo "Aliases:"' >> /usr/local/bin/magento-services && \
    echo '    echo "  start-all     # Same as start"' >> /usr/local/bin/magento-services && \
    echo '    echo "  start-core    # Same as start-quick"' >> /usr/local/bin/magento-services && \
    echo '    echo ""' >> /usr/local/bin/magento-services && \
    echo '    echo "Examples:"' >> /usr/local/bin/magento-services && \
    echo '    echo "  $0 elasticsearch start   # Start only Elasticsearch"' >> /usr/local/bin/magento-services && \
    echo '    echo "  $0 elasticsearch status  # Check Elasticsearch status"' >> /usr/local/bin/magento-services && \
    echo '    exit 1' >> /usr/local/bin/magento-services && \
    echo '    ;;' >> /usr/local/bin/magento-services && \
    echo 'esac' >> /usr/local/bin/magento-services && \
    chmod +x /usr/local/bin/magento-services

# Set permissions and ownership
RUN chown -R vscode:vscode /etc/php /etc/nginx /workspaces /home/vscode

# Create helpful aliases
RUN echo 'alias magento="php bin/magento"' >> /home/vscode/.bashrc && \
    echo 'alias ll="ls -la"' >> /home/vscode/.bashrc && \
    echo 'alias magerun="n98-magerun2"' >> /home/vscode/.bashrc && \
    echo 'alias versions="magento-versions"' >> /home/vscode/.bashrc && \
    echo 'alias services="magento-services"' >> /home/vscode/.bashrc && \
    echo 'alias start-all="magento-services start"' >> /home/vscode/.bashrc && \
    echo 'alias start-core="magento-services start-quick"' >> /home/vscode/.bashrc && \
    echo 'alias stop-all="magento-services stop"' >> /home/vscode/.bashrc && \
    echo 'alias restart-all="magento-services restart"' >> /home/vscode/.bashrc && \
    echo 'alias status-all="magento-services status"' >> /home/vscode/.bashrc && \
    echo 'alias test-db="test-mysql"' >> /home/vscode/.bashrc && \
    echo 'alias mysql="mariadb"' >> /home/vscode/.bashrc && \
    echo 'alias fix-mysql="fix-mysql-auth"' >> /home/vscode/.bashrc && \
    echo 'alias xdebug-on="magento-xdebug-enable"' >> /home/vscode/.bashrc && \
    echo 'alias xdebug-off="magento-xdebug-disable"' >> /home/vscode/.bashrc && \
    echo 'alias blackfire-config="blackfire-setup"' >> /home/vscode/.bashrc && \
    echo 'alias newrelic-install="newrelic-setup"' >> /home/vscode/.bashrc && \
    echo 'alias rabbitmq-config="rabbitmq-setup"' >> /home/vscode/.bashrc && \
    echo 'alias rabbitmq-diagnose="rabbitmq-diagnose"' >> /home/vscode/.bashrc && \
    echo 'cd /workspaces/magento2gitpod' >> /home/vscode/.bashrc /home/vscode/.bashrc && \
    echo 'alias mysql="mariadb -u root -pnem4540"' >> /home/vscode/.bashrc && \
    echo 'alias xdebug-on="magento-xdebug-enable"' >> /home/vscode/.bashrc && \
    echo 'alias xdebug-off="magento-xdebug-disable"' >> /home/vscode/.bashrc && \
    echo 'alias blackfire-config="blackfire-setup"' >> /home/vscode/.bashrc && \
    echo 'alias newrelic-install="newrelic-setup"' >> /home/vscode/.bashrc && \
    echo 'alias rabbitmq-config="rabbitmq-setup"' >> /home/vscode/.bashrc && \
    echo 'cd /workspaces/magento2gitpod' >> /home/vscode/.bashrc

# Set working directory
WORKDIR /workspaces/magento2gitpod

# Switch to vscode user
USER vscode

# Expose ports
EXPOSE 8002 9001 15672 8000 3306 6379 9200 9300

# Add build info
RUN echo "🚀 Modern Magento 2 environment ready!" && \
    echo "📦 PHP ${PHP_VERSION}, MariaDB ${MARIADB_VERSION}, Elasticsearch ${ELASTICSEARCH_VERSION}"
