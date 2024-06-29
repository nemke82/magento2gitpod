sudo supervisorctl stop mysql;
sudo percona-release enable ps-80 release;
sudo wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo apt-get update -y;
set -ex; \
	{ \
		for key in \
			percona-server-server/root_password \
			percona-server-server/root_password_again \
			"percona-server-server-$PERCONA_MAJOR/root-pass" \
			"percona-server-server-$PERCONA_MAJOR/re-root-pass" \
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
