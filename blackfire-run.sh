#!/bin/bash

variables=( "BLACKFIRE_SERVER_ID" "BLACKFIRE_SERVER_TOKEN" "BLACKFIRE_CLIENT_ID" "BLACKFIRE_CLIENT_TOKEN" "BLACKFIRE_SOCKET" "BLACKFIRE_LOG_LEVEL" "BLACKFIRE_LOG_FILE")

for var in "${variables[@]}"
do
   :
   sed -i "s|%$var%|${!var}|g" /etc/blackfire/agent
   sed -i "s|%$var%|${!var}|g" /etc/php/7.2/fpm/conf.d/92-blackfire-config.ini
   sed -i "s|%$var%|${!var}|g" /etc/php/7.2/cli/conf.d/92-blackfire-config.ini
done

blackfire-agent --register
/etc/init.d/blackfire-agent restart

blackfire config

cat /etc/blackfire/agent | grep "server-id=" | sed 's/server-id/blackfire.server_id/' >> /etc/php/7.2/cli/conf.d/92-blackfire-config.ini
cat /etc/blackfire/agent | grep "server-token=" | sed 's/server-token/blackfire.server_token/' >> /etc/php/7.2/cli/conf.d/92-blackfire-config.ini

#restart php7.2-fpm
service php7.2-fpm reload && service php7.2-fpm restart
