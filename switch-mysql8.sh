#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Stop MySQL service and supervisor
sudo supervisorctl stop mysql

# Temporarily move existing MySQL data directory
if [ -d /workspace/magento2gitpod/mysql ]; then
    sudo mv /workspace/magento2gitpod/mysql /workspace/magento2gitpod/mysql.bak
fi

# Enable Percona release and import Google signing key
sudo percona-release enable ps-80 release
sudo wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo apt-get update -y

# Preconfigure debconf selections
echo "percona-server-server percona-server-server/root_password password nem4540" | sudo debconf-set-selections
echo "percona-server-server percona-server-server/root_password_again password nem4540" | sudo debconf-set-selections
echo "percona-server-server-8.0 percona-server-server/root-pass password nem4540" | sudo debconf-set-selections
echo "percona-server-server-8.0 percona-server-server/re-root-pass password nem4540" | sudo debconf-set-selections
echo "percona-server-server percona-server-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)" | sudo debconf-set-selections

#fix apparmor profile
sudo rm -f /etc/apparmor.d/usr.sbin.mysqld

# Install Percona server packages
sudo apt-get install -y percona-server-server percona-server-client percona-server-common

# Update MySQL configuration
sed -i 's#query_cache_limit=2M##g' /etc/mysql/conf.d/mysqld.cnf
sed -i 's#query_cache_size=128M##g' /etc/mysql/conf.d/mysqld.cnf
sed -i 's#query_cache_type=1##g' /etc/mysql/conf.d/mysqld.cnf
echo "default_authentication_plugin=mysql_native_password" | sudo tee -a /etc/mysql/conf.d/mysqld.cnf

# Check if workdir is already set and replace it, otherwise add it
if grep -q "^workdir=" /etc/mysql/conf.d/mysqld.cnf; then
    sudo sed -i 's#^workdir=.*#workdir=/workspace/magento2gitpod#' /etc/mysql/conf.d/mysqld.cnf
else
    echo "workdir=/workspace/magento2gitpod" | sudo tee -a /etc/mysql/conf.d/mysqld.cnf
fi

# Set permissions and restart MySQL
sudo chown -R gitpod:gitpod /var/run/mysqld/
sudo supervisorctl start mysql
