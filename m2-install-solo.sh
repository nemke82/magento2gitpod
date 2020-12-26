#!/bin/bash

# Clone M2 repository (dev), for composer comment these lines and use following
# composer create-project --repository=https://repo.magento.com/ magento/project-community-edition magento2

cd /workspace/magento2gitpod &&
git clone https://github.com/magento/magento2.git && cd magento2 && cp -avr .* /workspace/magento2gitpod &&
cd /workspace/magento2gitpod && rm -r -f magento2 &&

#getting URL
url=$(gp url | awk -F"//" {'print $2'}) && url+="/" && url="https://8002-"$url
echo $url &&

#starting Redis and ElasticSearch services
redis-server &
$ES_HOME78/bin/elasticsearch -d -p $ES_HOME78/pid -Ediscovery.type=single-node &

mysql -u root -pnem4540 -e 'create database nemanja;' &&
url=$(gp url | awk -F"//" {'print $2'});url+="/";url="https://8002-"$url;cd /workspace/magento2gitpod && composer install && php bin/magento setup:install --db-name='nemanja' --db-user='root' --db-password='nem4540' --base-url=$url --backend-frontname='admin' --admin-user='admin' --admin-password='adm4540' --admin-email='ne@nemanja.io' --admin-firstname='Nemanja' --admin-lastname='Djuric' --use-rewrites='1' --use-secure='1' --base-url-secure=$url --use-secure-admin='1' --language='en_US' --db-host='127.0.0.1' --cleanup-database --timezone='America/New_York' --currency='USD' --session-save='redis' --amqp-host="127.0.0.1" --amqp-port="5672" --amqp-user="guest" --amqp-password="guest" --amqp-virtualhost="/"

n98-magerun2 module:disable Magento_Csp &&
n98-magerun2 module:disable Magento_TwoFactorAuth &&
n98-magerun2 setup:upgrade &&

yes | php bin/magento setup:config:set -n -q --session-save=redis --session-save-redis-host=127.0.0.1 --session-save-redis-log-level=3 --session-save-redis-db=0 --session-save-redis-port=6379 &&
yes | php bin/magento setup:config:set -n -q --cache-backend=redis --cache-backend-redis-server=127.0.0.1 --cache-backend-redis-db=1 &&
yes | php bin/magento setup:config:set -n -q --page-cache=redis --page-cache-redis-server=127.0.0.1 --page-cache-redis-db=2

php bin/magento config:set -n -q web/cookie/cookie_path "/" --lock-config &&
php bin/magento config:set -n -q web/cookie/cookie_domain ".gitpod.io" --lock-config &&

n98-magerun2 cache:clean &&
n98-magerun2 cache:flush &&
redis-cli flushall &&

echo "Click here and then Open Browser button  --------------------------------------------------------------"
echo "                                                                                                      |"
