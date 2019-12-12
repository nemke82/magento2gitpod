#!/bin/bash

blackfire-agent --register
blackfire config

cat /etc/blackfire/agent | grep "client-id=" | sed 's/server-id/blackfire.client_id/' >> /etc/php/7.2/cli/conf.d/92-blackfire-config.ini
cat /etc/blackfire/agent | grep "client-token=" | sed 's/server-token/blackfire.client_token/' >> /etc/php/7.2/cli/conf.d/92-blackfire-config.ini

cat /etc/blackfire/agent | grep "server-id=" | sed 's/server-id/blackfire.server_id/' >> /etc/php/7.2/fpm/conf.d/92-blackfire-config.ini
cat /etc/blackfire/agent | grep "server-token=" | sed 's/server-token/blackfire.server_token/' >> /etc/php/7.2/fpm/conf.d/92-blackfire-config.ini

sed -i '/blackfire.agent_socket/d' /etc/php/7.2/fpm/conf.d/92-blackfire-config.ini
sed -i '/blackfire.agent_socket/d' /etc/php/7.2/cli/conf.d/92-blackfire-config.ini

echo "blackfire.agent_socket=unix:///tmp/agent.sock" >> /etc/php/7.2/fpm/conf.d/92-blackfire-config.ini
echo "blackfire.agent_socket=unix:///tmp/agent.sock" >> /etc/php/7.2/cli/conf.d/92-blackfire-config.ini

#restart php7.2-fpm
service php7.2-fpm stop && service php7.2-fpm restart

blackfire-agent --socket=unix:///tmp/agent.sock &
