#!/bin/bash
cd /workspace/magento2gitpod &&
tar -xvf magento-2.3.3.tar.gz &&
mysql -e 'create database nemanja;' &&
url=$(gp url) &&
url+="/"

redis-server &

php bin/magento setup:install --db-name='nemanja' --db-user='root' --db-password='' --base-url=$url --backend-frontname='admin' --admin-user='admin' --admin-password='adm4540' --admin-email='ne@nemanja.io' --admin-firstname='Nemanja' --admin-lastname='Djuric' --use-rewrites='1' --use-secure='1' --base-url-secure=$url --use-secure-admin='1' --language='en_US' --db-host='127.0.0.1' --cleanup-database --timezone='America/New_York' --currency='USD' --session-save='redis'

php bin/magento setup:config:set --session-save=redis --session-save-redis-host=127.0.0.1 --session-save-redis-log-level=3 --session-save-redis-db=0 --session-save-redis-port=6379 &&
php bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=127.0.0.1 --cache-backend-redis-db=1 &&
php bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=127.0.0.1 --page-cache-redis-db=2

php bin/magento config:set web/cookie/cookie_path "/" --lock-env &&
php bin/magento config:set web/cookie/cookie_domain ".gitpod.io" --lock-env &&

echo "Click here and then Open Browser button  --------------------------------------------------------------"
echo "                                                                                                      |"
