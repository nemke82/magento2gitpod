#!/bin/bash
sudo composer selfupdate --2;
sudo chown -R gitpod:gitpod /home/gitpod/.config/composer;
cd /workspace/magento2gitpod &&
composer config -g -a http-basic.repo.magento.com 64229a8ef905329a184da4f174597d25 a0df0bec06011c7f1e8ea8833ca7661e &&
composer create-project --no-interaction --no-progress --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.6-p6 magento2
cd magento2 && cp -avr .* /workspace/magento2gitpod;
cd /workspace/magento2gitpod && rm -r -f magento2;
mysql -e 'create database nemanja;';
url=$(gp url | awk -F"//" {'print $2'}) && url+="/" && url="https://8002-"$url;

mysql -u root -pnem4540 -e 'create database nemanja;' &&
url=$(gp url | awk -F"//" {'print $2'}) && url+="/" && url="https://8002-"$url;cd /workspace/magento2gitpod && composer install -n && php bin/magento setup:install --db-name='nemanja' --db-user='root' --db-password='nem4540' --base-url=$url --backend-frontname='admin' --admin-user='admin' --admin-password='adm4540' --admin-email='ne@nemanja.io' --admin-firstname='Nemanja' --admin-lastname='Djuric' --use-rewrites='1' --use-secure='1' --base-url-secure=$url --use-secure-admin='1' --language='en_US' --db-host='127.0.0.1' --cleanup-database --timezone='America/New_York' --currency='USD' --session-save='redis' --amqp-host="127.0.0.1" --amqp-port="5672" --amqp-user="guest" --amqp-password="guest" --amqp-virtualhost="/"

# Remove the existing n98-magerun2 if it exists
sudo rm -f /usr/local/bin/n98-magerun2

# Change to the /usr/local/bin directory
cd /usr/local/bin

# Download the latest version of n98-magerun2
sudo wget -c https://files.magerun.net/n98-magerun2.phar

# Rename the downloaded file
sudo mv n98-magerun2.phar n98-magerun2

# Make the file executable
sudo chmod a+rwx n98-magerun2

echo "n98-magerun2 has been updated to the latest version."

# Change back to workspace directory
cd /workspace/magento2gitpod

n98-magerun2 module:disable Magento_AdminAdobeImsTwoFactorAuth &&
n98-magerun2 module:disable Magento_TwoFactorAuth &&
n98-magerun2 setup:upgrade &&

yes | php bin/magento setup:config:set --session-save=redis --session-save-redis-host=127.0.0.1 --session-save-redis-log-level=3 --session-save-redis-db=0 --session-save-redis-port=6379;
yes | php bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=127.0.0.1 --cache-backend-redis-db=1;
yes | php bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=127.0.0.1 --page-cache-redis-db=2;

php bin/magento config:set web/cookie/cookie_path "/" --lock-config &&
php bin/magento config:set web/cookie/cookie_domain ".gitpod.io" --lock-config &&
php bin/magento config:set web/secure/offloader_header "X-Forwarded-Proto" --lock-config &&

n98-magerun2 cache:clean &&
n98-magerun2 cache:flush &&
redis-cli flushall &&

echo "Click here and then Open Browser button  --------------------------------------------------------------"
echo "                                                                                                      |"
