#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export PERCONA_MAJOR=8.0

sudo supervisorctl stop mysql;
sudo percona-release enable ps-80 release;
sudo apt-get update -y;
set -ex; \
	{ \
		for key in \
			percona-server-server/root_password \
			percona-server-server/root_password_again \
			"percona-server-server-$PERCONA_MAJOR/root-pass" \
			"percona-server-server-$PERCONA_MAJOR/re-root-pass" \
            "percona-server-server percona-server-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)" \
            "percona-server-server-8.0 percona-server-server/use-exist-apparmor-profile select Use existent AppArmor profile (RECOMMENDED)" \
		; do \
			sudo echo "percona-server-server-$PERCONA_MAJOR" "$key" password 'nem4540'; \
		done; \
	} | sudo debconf-set-selections;
sudo apt-get update;
sudo apt-get upgrade -y percona-server-server percona-server-client percona-server-common;
sed -i 's#query_cache_limit=2M##g' /etc/mysql/conf.d/mysqld.cnf;
sed -i 's#query_cache_size=128M##g' /etc/mysql/conf.d/mysqld.cnf;
sed -i 's#query_cache_type=1##g' /etc/mysql/conf.d/mysqld.cnf;
sudo echo "default_authentication_plugin=mysql_native_password" >> /etc/mysql/conf.d/mysqld.cnf;
sudo chown -R gitpod:gitpod /var/run/mysqld/;
sudo supervisorctl start mysql
