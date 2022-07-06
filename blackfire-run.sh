#!/bin/bash
clear;
sudo apt update;
sudo apt install --only-upgrade blackfire-php;
sudo apt install --only-upgrade blackfire;

blackfire-agent --register
blackfire config

cat /etc/blackfire/agent | grep "client-id=" | sed 's/server-id/blackfire.client_id/' >> /etc/php/$(php -v | awk 'NR=1{print substr($2,1,3); exit}')/cli/conf.d/92-blackfire-config.ini
cat /etc/blackfire/agent | grep "client-token=" | sed 's/server-token/blackfire.client_token/' >> /etc/php/$(php -v | awk 'NR=1{print substr($2,1,3); exit}')/cli/conf.d/92-blackfire-config.ini

cat /etc/blackfire/agent | grep "server-id=" | sed 's/server-id/blackfire.server_id/' >> /etc/php/$(php -v | awk 'NR=1{print substr($2,1,3); exit}')/fpm/conf.d/92-blackfire-config.ini
cat /etc/blackfire/agent | grep "server-token=" | sed 's/server-token/blackfire.server_token/' >> /etc/php/$(php -v | awk 'NR=1{print substr($2,1,3); exit}')/fpm/conf.d/92-blackfire-config.ini

sed -i '/blackfire.agent_socket/d' /etc/php/$(php -v | awk 'NR=1{print substr($2,1,3); exit}')/fpm/conf.d/92-blackfire-config.ini
sed -i '/blackfire.agent_socket/d' /etc/php/$(php -v | awk 'NR=1{print substr($2,1,3); exit}')/cli/conf.d/92-blackfire-config.ini

echo "blackfire.agent_socket=unix:///tmp/agent.sock" >> /etc/php/$(php -v | awk 'NR=1{print substr($2,1,3); exit}')/fpm/conf.d/92-blackfire-config.ini
echo "blackfire.agent_socket=unix:///tmp/agent.sock" >> /etc/php/$(php -v | awk 'NR=1{print substr($2,1,3); exit}')/cli/conf.d/92-blackfire-config.ini

#restart php-fpm
sudo supervisorctl restart php-fpm

blackfire-agent --socket=unix:///tmp/agent.sock &
