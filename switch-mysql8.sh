#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Stop MySQL service
sudo supervisorctl stop mysql

# Remove existing Percona packages
sudo apt-get remove --purge -y percona-server-server-8.0 percona-server-client-8.0 percona-server-common-8.0
sudo apt-get autoremove -y
sudo apt-get clean

# Remove the MySQL directory
sudo rm -rf /workspace/magento2gitpod/mysql

# Update package list and install gnupg2
sudo apt-get update \
 && sudo apt-get -y install gnupg2 \
 && sudo apt-get clean \
 && sudo rm -rf /var/cache/apt/* /var/lib/apt/lists/* /tmp/*

# Create necessary directories
sudo mkdir -p /var/run/mysqld

# Download and install Percona release package
sudo wget -c https://repo.percona.com/apt/percona-release_latest.generic_all.deb \
 && sudo dpkg -i percona-release_latest.generic_all.deb \
 && sudo apt-get update

# Preconfigure debconf selections for Percona installation
sudo debconf-set-selections <<EOF
percona-server-server-8.0 percona-server-server/root_password password nem4540
percona-server-server-8.0 percona-server-server/root_password_again password nem4540
percona-server-server-8.0/root-pass password nem4540
percona-server-server-8.0/re-root-pass password nem4540
EOF

# Install Percona server packages
sudo apt-get update \
 && sudo apt-get install -y \
    percona-server-server-8.0 percona-server-client-8.0 percona-server-common-8.0

# Change ownership of MySQL directories
sudo chown -R gitpod:gitpod /etc/mysql /var/run/mysqld /var/log/mysql /var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring

# Copy MySQL configuration files
sudo cp mysql.cnf /etc/mysql/conf.d/mysqld.cnf
sudo cp .my.cnf /home/gitpod
sudo cp mysql.conf /etc/supervisor/conf.d/mysql.conf
sudo chown gitpod:gitpod /home/gitpod/.my.cnf

# Copy default-login for MySQL clients
sudo cp client.cnf /etc/mysql/conf.d/client.cnf

# Start MySQL service
sudo supervisorctl start mysql
