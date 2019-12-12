#!/bin/bash

blackfire-agent --register
blackfire config

cat /etc/blackfire/agent | grep "server-id=" | sed 's/server-id/blackfire.server_id/' >> /etc/php/7.2/cli/conf.d/92-blackfire-config.ini
cat /etc/blackfire/agent | grep "server-token=" | sed 's/server-token/blackfire.server_token/' >> /etc/php/7.2/cli/conf.d/92-blackfire-config.ini

blackfire-agent --socket="unix:///tmp/agent.sock" &

#restart php7.2-fpm
service php7.2-fpm reload && service php7.2-fpm restart
