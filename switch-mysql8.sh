#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export PERCONA_MAJOR=8.0

sudo supervisorctl stop mysql;
sudo percona-release enable ps-80 release;
sudo apt-get update -y;

# Preconfigure debconf selections for Percona installation
echo "percona-server-server-8.0 percona-server-server/root_password password nem4540" | sudo debconf-set-selections
echo "percona-server-server-8.0 percona-server-server/root_password_again password nem4540" | sudo debconf-set-selections
echo "percona-server-server-8.0 percona-server-server/root-pass password nem4540" | sudo debconf-set-selections
echo "percona-server-server-8.0 percona-server-server/re-root-pass password nem4540" | sudo debconf-set-selections
echo "percona-server-server-8.0 percona-server-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)" | sudo debconf-set-selections
echo "percona-server-server-8.0 percona-server-server/use-exist-apparmor-profile select Use existent AppArmor profile (RECOMMENDED)" | sudo debconf-set-selections
sudo apt-get update;
sudo rm -r -f /var/lib/mysql;
sudo apt-get upgrade -y percona-server-server percona-server-client percona-server-common;
sed -i 's#query_cache_limit=2M##g' /etc/mysql/conf.d/mysqld.cnf;
sed -i 's#query_cache_size=128M##g' /etc/mysql/conf.d/mysqld.cnf;
sed -i 's#query_cache_type=1##g' /etc/mysql/conf.d/mysqld.cnf;
sudo echo "default_authentication_plugin=mysql_native_password" >> /etc/mysql/conf.d/mysqld.cnf;
sudo chown -R gitpod:gitpod /var/run/mysqld/;
sudo supervisorctl start mysql
