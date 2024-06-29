#!/bin/bash

sudo supervisorctl stop mysql
sudo percona-release enable ps-80 release
sudo wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo apt-get update -y

# Preconfigure debconf selections
echo "percona-server-server percona-server-server/root_password password nem4540" | sudo debconf-set-selections
echo "percona-server-server percona-server-server/root_password_again password nem4540" | sudo debconf-set-selections
echo "percona-server-server-8.0 percona-server-server/root-pass password nem4540" | sudo debconf-set-selections
echo "percona-server-server-8.0 percona-server-server/re-root-pass password nem4540" | sudo debconf-set-selections
echo "percona-server-server percona-server-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)" | sudo debconf-set-selections

# Install and upgrade Percona server packages
sudo apt-get update
sudo apt-get upgrade -y percona-server-server percona-server-client percona-server-common

# Update MySQL configuration
sed -i 's#query_cache_limit=2M##g' /etc/mysql/conf.d/mysqld.cnf
sed -i 's#query_cache_size=128M##g' /etc/mysql/conf.d/mysqld.cnf
sed -i 's#query_cache_type=1##g' /etc/mysql/conf.d/mysqld.cnf
echo "default_authentication_plugin=mysql_native_password" | sudo tee -a /etc/mysql/conf.d/mysqld.cnf

# Set permissions and restart MySQL
sudo chown -R gitpod:gitpod /var/run/mysqld/
sudo supervisorctl start mysql
