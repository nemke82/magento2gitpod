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

/bin/bash /run.sh
