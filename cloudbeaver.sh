sudo supervisorctl stop mysql;
sudo sed -i 's/127.0.0.1/0.0.0.0/' /etc/mysql/conf.d/mysqld.cnf;
sudo supervisorctl start mysql;
sudo apt-get update; sudo apt-get install net-tools -y;
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'nem4540';";
mysql -e "flush privileges;";
export CB_LOCAL_HOST_ADDR=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1);
docker run --name cloudbeaver -d --rm -ti -p 8003:8978 --add-host=host.docker.internal:${CB_LOCAL_HOST_ADDR} -v /var/cloudbeaver/workspace:/opt/cloudbeaver/workspace dbeaver/cloudbeaver:dev
