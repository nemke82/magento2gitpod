#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Stop MySQL service and supervisor
sudo supervisorctl stop mysql

# Temporarily move existing MySQL data directory
if [ -d /var/lib/mysql ]; then
    sudo mv /var/lib/mysql /var/lib/mysql.bak
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

# Install Percona server packages
sudo apt-get install -y percona-server-server percona-server-client percona-server-common

# Restore the original data directory
if [ -d /var/lib/mysql.bak ]; then
    sudo rm -rf /var/lib/mysql
    sudo mv /var/lib/mysql.bak /var/lib/mysql
    sudo chown -R mysql:mysql /var/lib/mysql
fi

# Update MySQL configuration
sed -i 's#query_cache_limit=2M##g' /etc/mysql/conf.d/mysqld.cnf
sed -i 's#query_cache_size=128M##g' /etc/mysql/conf.d/mysqld.cnf
sed -i 's#query_cache_type=1##g' /etc/mysql/conf.d/mysqld.cnf
echo "default_authentication_plugin=mysql_native_password" | sudo tee -a /etc/mysql/conf.d/mysqld.cnf

# Set permissions and restart MySQL
sudo chown -R gitpod:gitpod /var/run/mysqld/
sudo supervisorctl start mysql
