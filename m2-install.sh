#!/bin/bash

echo "=============================================="
echo "Magento 2.4.8-p2 Installation for ONA Platform"
echo "=============================================="

# Ensure we're in the correct directory
cd /workspaces/magento2gitpod

# Update Composer to version 2
echo "Updating Composer..."
sudo composer selfupdate --2
sudo chown -R vscode:vscode /home/vscode/.composer

# Configure Magento repository credentials
echo "Configuring Magento repository access..."
composer config -g -a http-basic.repo.magento.com 64229a8ef905329a184da4f174597d25 a0df0bec06011c7f1e8ea8833ca7661e

# Create Magento project
echo "Creating Magento 2.4.8-p2 project..."
composer create-project --no-interaction --no-progress --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.8-p2 magento2

# Move files to workspace root
echo "Moving Magento files to workspace..."
cd magento2 && cp -avr .* /workspaces/magento2gitpod
cd /workspaces/magento2gitpod && rm -r -f magento2

# Create database
echo "Creating database..."
mysql -u root -pnem4540 -e 'CREATE DATABASE IF NOT EXISTS nemanja;'

# Install Composer dependencies
echo "Installing Composer dependencies..."
composer install -n

# Expose port 8002 using ONA method and capture the URL
echo "Exposing port 8002 for web access..."
if command -v gitpod >/dev/null 2>&1; then
    # Use ONA command which returns the URL directly
    BASE_URL=$(gitpod environment port open 8002 --name nginx)
    echo "Port exposed, URL: $BASE_URL"
else
    # Local development fallback
    BASE_URL="http://localhost:8002"
    echo "Local development mode, using: $BASE_URL"
fi

echo "Base URL will be: $BASE_URL"

# Install Magento with ONA-optimized settings
echo "Installing Magento 2..."
php bin/magento setup:install \
    --db-name='nemanja' \
    --db-user='root' \
    --db-password='nem4540' \
    --base-url="$BASE_URL" \
    --backend-frontname='admin' \
    --admin-user='admin' \
    --admin-password='adm4540' \
    --admin-email='ne@nemanja.io' \
    --admin-firstname='Nemanja' \
    --admin-lastname='Djuric' \
    --use-rewrites='1' \
    --use-secure='1' \
    --base-url-secure="$BASE_URL" \
    --use-secure-admin='1' \
    --language='en_US' \
    --db-host='127.0.0.1' \
    --cleanup-database \
    --timezone='America/New_York' \
    --currency='USD' \
    --session-save='redis' \
    --amqp-host="127.0.0.1" \
    --amqp-port="5672" \
    --amqp-user="guest" \
    --amqp-password="guest" \
    --amqp-virtualhost="/"

# Update n98-magerun2 to latest version
echo "Updating n98-magerun2..."
sudo rm -f /usr/local/bin/n98-magerun2
cd /usr/local/bin
sudo wget -c https://files.magerun.net/n98-magerun2.phar
sudo mv n98-magerun2.phar n98-magerun2
sudo chmod a+rwx n98-magerun2
cd /workspaces/magento2gitpod

# Disable Two-Factor Authentication for development
echo "Disabling Two-Factor Authentication..."
n98-magerun2 module:disable Magento_AdminAdobeImsTwoFactorAuth
n98-magerun2 module:disable Magento_TwoFactorAuth
n98-magerun2 setup:upgrade

# Configure Redis for sessions, cache, and page cache
echo "Configuring Redis..."
yes | php bin/magento setup:config:set --session-save=redis --session-save-redis-host=127.0.0.1 --session-save-redis-log-level=3 --session-save-redis-db=0 --session-save-redis-port=6379;
yes | php bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=127.0.0.1 --cache-backend-redis-db=1;
yes | php bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=127.0.0.1 --page-cache-redis-db=2;

# Configure for ONA environment
echo "Configuring for ONA environment..."
php bin/magento config:set web/cookie/cookie_path "/" --lock-config
php bin/magento config:set web/cookie/cookie_domain ".gitpod.dev" --lock-config
php bin/magento config:set web/secure/offloader_header "X-Forwarded-Proto" --lock-config

# Clear all caches
echo "Clearing caches..."
n98-magerun2 cache:clean
n98-magerun2 cache:flush
redis-cli flushall

# Set proper permissions
echo "Setting file permissions..."
sudo chown -R vscode:vscode /workspaces/magento2gitpod
find /workspaces/magento2gitpod -type d -exec chmod 755 {} \;
find /workspaces/magento2gitpod -type f -exec chmod 644 {} \;
chmod +x /workspaces/magento2gitpod/bin/magento

echo ""
echo "=============================================="
echo "Magento 2.4.8-p2 Installation Complete!"
echo "=============================================="
echo ""
echo "Access your Magento store:"
echo "Frontend: $BASE_URL"
echo "Admin: ${BASE_URL}admin"
echo ""
echo "Admin Credentials:"
echo "Username: admin"
echo "Password: adm4540"
echo ""
echo "Database:"
echo "Name: nemanja"
echo "User: root"
echo "Password: nem4540"
echo ""
echo "Next Steps:"
echo "1. Open Browser and visit ${BASE_URL}"
echo "2. Or use the URL above to access your store"
echo "3. Run 'test-db' to verify database connection"
echo "=============================================="
