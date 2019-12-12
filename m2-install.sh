#!/bin/bash
cd /workspace/magento2gitpod &&
tar -xvf magento-2.3.3.tar.gz &&
mysql -e 'create database nemanja;' &&
url=$(gp url)
url+="/"

php bin/magento setup:install --db-name='nemanja' --db-user='root' --db-password='' --base-url=$url --backend-frontname='admin' --admin-user='admin' --admin-password='adm4540' --admin-email='ne@nemanja.io' --admin-firstname='Nemanja' --admin-lastname='Djuric' --use-rewrites='1' --use-secure='1' --base-url-secure=$url --use-secure-admin='1' --language='en_US' --db-host='localhost' --cleanup-database --timezone='America/New_York' --currency='USD' --session-save='files'

echo "Click here and then Open Browser button  --------------------------------------------------------------"
echo "                                                                                                      |"
