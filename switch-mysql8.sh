#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Stop MySQL service
sudo supervisorctl stop mysql

# Remove existing Percona packages
DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y percona-server-server-5.7 percona-server-client-5.7 percona-server-common-5.7 percona-server-server percona-server-client percona-server-common
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
 && sudo apt-get update -y

# Preconfigure debconf selections for Percona installation
echo "percona-server-server-8.0 percona-server-server/root_password password nem4540" | sudo debconf-set-selections
echo "percona-server-server-8.0 percona-server-server/root_password_again password nem4540" | sudo debconf-set-selections
echo "percona-server-server-8.0 percona-server-server/root-pass password nem4540" | sudo debconf-set-selections
echo "percona-server-server-8.0 percona-server-server/re-root-pass password nem4540" | sudo debconf-set-selections
echo "percona-server-server percona-server-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)" | sudo debconf-set-selections
echo "percona-server-server-8.0 percona-server-server/use-exist-apparmor-profile select Use existent AppArmor profile (RECOMMENDED)" | sudo debconf-set-selections

# Install Percona server packages
sudo percona-release setup ps80
sudo apt-get update -y \
 && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    percona-server-server percona-server-client percona-server-common

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
