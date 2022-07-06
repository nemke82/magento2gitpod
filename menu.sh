#!/bin/bash

# while-menu-dialog: a menu driven system information program

DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0

display_result() {
  dialog --title "$1" \
    --no-collapse \
    --msgbox "$result" 0 0
}

while true; do
  exec 3>&1
  selection=$(dialog \
    --backtitle "Installer/Services menu" \
    --title "Menu" \
    --clear \
    --cancel-label "Exit" \
    --menu "Please select:" $HEIGHT $WIDTH 4 \
    "1" "Display System Information" \
    "2" "Display Disk Space" \
    "3" "Display Home Space Utilization" \
    "4" "Install Magento 2.4.4 latest" \
    "5" "Install Magento 2.4.3-p2" \
    "6" "Install Magento 2.4-develop (dev)" \
    "7" "Install Baler tool" \
    "8" "Install MagePack tool" \
    "9" "Start Redis service" \
    "10" "Stop Redis service" \
    "11" "Start ElasticSearch service" \
    "12" "Stop ElasticSearch service" \
    "13" "Start Blackfire service" \
    "14" "Stop Blackfire service" \
    "15" "Start Newrelic service" \
    "16" "Stop Newrelic service" \
    "17" "Start Tideways service" \
    "18" "Stop Tideways service" \
    "19" "Start xDebug service" \
    "20" "Stop xDebug service" \
    "21" "Start xDebug 2.9.7 service" \
    "22" "Stop xDebug 2.9.7 service" \
    "23" "Start Cron service" \
    "24" "Install PWA Studio" \
    "25" "Install CloudBeaver" \
    "26" "Install MailHog SMTP server" \
    "27" "Switch to PHP 7.3 CLI+FPM" \
    "28" "Switch to PHP 8.1 CLI+FPM" \
    "29" "Switch to MySQL 8" \
    "30" "Start and Configure Varnish 6" \
    "31" "Start and Configure Varnish 7" \
    "32" "Stop Varnish 6 or 7" \
    2>&1 1>&3)
  exit_status=$?
  exec 3>&-
  case $exit_status in
    $DIALOG_CANCEL)
      clear
      echo "Program terminated."
      exit
      ;;
    $DIALOG_ESC)
      clear
      echo "Program aborted." >&2
      exit 1
      ;;
  esac
  case $selection in
    0 )
      clear
      echo "Program terminated."
      ;;
    1 )
      result=$(echo "Hostname: $HOSTNAME"; uptime)
      display_result "System Information"
      ;;
    2 )
      result=$(df -h)
      display_result "Disk Space"
      ;;
    3 )
      if [[ $(id -u) -eq 0 ]]; then
        result=$(du -sh /home/* 2> /dev/null)
        display_result "Home Space Utilization (All Users)"
      else
        result=$(du -sh $HOME 2> /dev/null)
        display_result "Home Space Utilization ($USER)"
      fi
      ;;
    4 )
      sed -i 's#composer create-project --no-interaction --no-progress --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.3#composer create-project --no-interaction --no-progress --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.4#g' m2-install.sh;
      chmod a+rwx m2-install.sh && ./m2-install.sh && clear
      result=$(url=$(gp url | awk -F"//" {'print $2'}) && url+="/" && url="https://8002-"$url;echo $url)
      display_result "Installation completed! Please visit"
      ;;
    5 )
      chmod a+rwx m2-install.sh && ./m2-install.sh && clear
      result=$(url=$(gp url | awk -F"//" {'print $2'}) && url+="/" && url="https://8002-"$url;echo $url)
      display_result "Installation completed! Please visit"
      ;;
    6 )
      chmod a+rwx m2-install-solo.sh && ./m2-install-solo.sh && clear
      result=$(url=$(gp url | awk -F"//" {'print $2'}) && url+="/" && url="https://8002-"$url;echo $url)
      display_result "Installation completed! Please visit"
      ;;
    7 )
      result=$(git clone https://github.com/magento/baler.git && cd baler && npm install && npm run build;alias baler='/workspace/magento2gitpod/baler/bin/baler'&)
      display_result "Baler tool successfully installed! Press enter to continue ..."
      ;;
    8 )
      result=$(cd /workspace/magento2gitpod && /usr/bin/php -dmemory_limit=20000M /usr/bin/composer require creativestyle/magesuite-magepack && n98-magerun2 setup:upgrade && n98-magerun2 setup:di:compile && n98-magerun2 setup:static-content:deploy && n98-magerun2 cache:clean && n98-magerun2 cache:flush && nvm install 14.5.0 && npm install -g magepack)
      display_result "MagePack tool successfully installed! Press enter to continue ... visit https://nemanja.io/speed-up-magento-2-page-load-rendering-using-magepack-method/ for more details how to proceed further"
      ;;
    9 )
      result=$(redis-server &)
      display_result "Redis service started! Press enter to continue ...Installation completed! Press enter to continue ..."
      ;;
    10 )
      result=$(ps aux | grep redis | awk {'print $2'} | xargs kill -s 9)
      display_result "Redis service stopped! Press enter to continue ..."
      ;;
    11 )
      result=$($ES_HOME/bin/elasticsearch -d -p $ES_HOME/pid -Ediscovery.type=single-node &)
      display_result "ElasticSearch service started! Press enter to continue ..."
      ;;
    12 )
      result=$(ps aux | grep elastic | awk {'print $2'} | xargs kill -s 9)
      display_result "ElasticSearch service stopped! Press enter to continue ..."
      ;;
    13 )
      chmod a+rwx ./blackfire-run.sh && ./blackfire-run.sh
      display_result "Blackfire service started! Press enter to continue ..."
      ;;
    14 )
      result=$(ps aux | grep blackfire | awk {'print $2'} | xargs kill -s 9)
      display_result "Blackfire service stopped! Press enter to continue ..."
      ;;
    15 )
      result=$(newrelic-daemon -c /etc/newrelic/newrelic.cfg &)
      display_result "Newrelic service started! Press enter to continue ... Please update .gitpod.Dockerfile (https://github.com/nemke82/magento2gitpod/blob/master/.gitpod.Dockerfile) with license key."
      ;;
    16 )
      result=$(ps aux | grep newrelic | awk {'print $2'} | xargs kill -s 9)
      display_result "Newrelic service stopped! Press enter to continue ..."
      ;;
    17 )
      result=$(/usr/bin/tideways-daemon --address 0.0.0.0:9135 &)
      display_result "Tideways service started! Press enter to continue ... Starting Tideways service, Please update .env-file located in repo with TIDEWAYS_APIKEY"
      ;;
    18 )
      result=$(ps aux | grep tideways | awk {'print $2'} | xargs kill -s 9)
      display_result "Tideways service stopped! Press enter to continue ..."
      ;;
    19 )
      sudo apt-get update;
      sudo apt-get install -y php7.4-dev;
      rm -f /etc/php/7.4/mods-available/xdebug.ini &&
      wget http://xdebug.org/files/xdebug-2.9.8.tgz && tar -xvf xdebug-2.9.8.tgz &&
      cd xdebug-2.9.8 && phpize && ./configure --with-php-config=/usr/bin/php-config7.4 && make && clear &&
      result=$(echo "Configuring xDebug PHP settings" &&
      echo "xdebug.remote_autostart=on" >> /etc/php/7.4/mods-available/xdebug.ini;
      echo "xdebug.profiler_enable=On" >> /etc/php/7.4/mods-available/xdebug.ini;
      echo "xdebug.remote_enable=1" >> /etc/php/7.4/mods-available/xdebug.ini;
      echo "xdebug.remote_port=9003" >> /etc/php/7.4/mods-available/xdebug.ini;
      echo "xdebug.profiler_output_name = nemanja.log" >> /etc/php/7.4/mods-available/xdebug.ini;
      echo "xdebug.show_error_trace=On" >> /etc/php/7.4/mods-available/xdebug.ini;
      echo "xdebug.show_exception_trace=On" >> /etc/php/7.4/mods-available/xdebug.ini;
      echo "zend_extension=/workspace/magento2gitpod/xdebug-2.9.8/modules/xdebug.so" >> /etc/php/7.4/mods-available/xdebug.ini;
      ln -s /etc/php/7.4/mods-available/xdebug.ini /etc/php/7.4/fpm/conf.d/20-xdebug.ini;
      ln -s /etc/php/7.4/mods-available/xdebug.ini /etc/php/7.4/cli/conf.d/20-xdebug.ini;
      service php7.4-fpm reload;clear)
      display_result "Services successfully configured and php-fpm restarted! Press enter to continue ..."
      ;;
    20 )
      result=$(echo "Configuring xDebug PHP settings" && echo "xdebug.remote_autostart=off" >> /etc/php/7.4/mods-available/xdebug.ini;
      echo "xdebug.profiler_enable=Off" >> /etc/php/7.4/mods-available/xdebug.ini;
      echo "xdebug.remote_enable=0" >> /etc/php/7.4/mods-available/xdebug.ini;
      echo "xdebug.remote_port=9003" >> /etc/php/7.4/mods-available/xdebug.ini;
      echo "xdebug.profiler_output_name = nemanja.log" >> /etc/php/7.4/mods-available/xdebug.ini;
      echo "xdebug.show_error_trace=Off" >> /etc/php/7.4/mods-available/xdebug.ini;
      echo "xdebug.show_exception_trace=Off" >> /etc/php/7.4/mods-available/xdebug.ini;
      mv /etc/php/7.4/fpm/conf.d/20-xdebug.ini /etc/php/7.4/fpm/conf.d/20-xdebug.ini-bak;
      mv /etc/php/7.4/cli/conf.d/20-xdebug.ini /etc/php/7.4/cli/conf.d/20-xdebug.ini-bak;
      service php7.4-fpm reload;)
      display_result "xDebug stopped! Press enter to continue ..."
      ;;
    21 )
      sudo apt-get update;
      sudo apt-get install -y php7.3-dev;
      rm -f /etc/php/7.3/mods-available/xdebug.ini &&
      wget http://xdebug.org/files/xdebug-2.9.7.tgz && tar -xvf xdebug-2.9.7.tgz &&
      cd xdebug-2.9.7 && phpize && ./configure --with-php-config=/usr/bin/php-config7.3 && make && clear &&
      result=$(echo "Configuring xDebug PHP settings" &&
      echo "xdebug.remote_autostart=on" >> /etc/php/7.3/mods-available/xdebug.ini;
      echo "xdebug.profiler_enable=On" >> /etc/php/7.3/mods-available/xdebug.ini;
      echo "xdebug.remote_enable=1" >> /etc/php/7.3/mods-available/xdebug.ini;
      echo "xdebug.remote_port=9003" >> /etc/php/7.3/mods-available/xdebug.ini;
      echo "xdebug.profiler_output_name = nemanja.log" >> /etc/php/7.3/mods-available/xdebug.ini;
      echo "xdebug.show_error_trace=On" >> /etc/php/7.3/mods-available/xdebug.ini;
      echo "xdebug.show_exception_trace=On" >> /etc/php/7.3/mods-available/xdebug.ini;
      echo "zend_extension=/workspace/magento2gitpod/xdebug-2.9.7/modules/xdebug.so" >> /etc/php/7.3/mods-available/xdebug.ini;
      ln -s /etc/php/7.3/mods-available/xdebug.ini /etc/php/7.3/fpm/conf.d/20-xdebug.ini;
      ln -s /etc/php/7.3/mods-available/xdebug.ini /etc/php/7.3/cli/conf.d/20-xdebug.ini;
      service php7.3-fpm reload;clear)
      display_result "Services successfully configured and php-fpm restarted! Press enter to continue ..."
      ;;
    22 )
      result=$(echo "Configuring xDebug PHP settings" && echo "xdebug.remote_autostart=off" >> /etc/php/7.3/mods-available/xdebug.ini;
      echo "xdebug.profiler_enable=Off" >> /etc/php/7.3/mods-available/xdebug.ini;
      echo "xdebug.remote_enable=0" >> /etc/php/7.3/mods-available/xdebug.ini;
      echo "xdebug.remote_port=9003" >> /etc/php/7.3/mods-available/xdebug.ini;
      echo "xdebug.profiler_output_name = nemanja.log" >> /etc/php/7.3/mods-available/xdebug.ini;
      echo "xdebug.show_error_trace=Off" >> /etc/php/7.3/mods-available/xdebug.ini;
      echo "xdebug.show_exception_trace=Off" >> /etc/php/7.3/mods-available/xdebug.ini;
      mv /etc/php/7.3/fpm/conf.d/20-xdebug.ini /etc/php/7.3/fpm/conf.d/20-xdebug.ini-bak;
      mv /etc/php/7.3/cli/conf.d/20-xdebug.ini /etc/php/7.3/cli/conf.d/20-xdebug.ini-bak;
      service php7.3-fpm reload;)
      display_result "xDebug 2.9.7 stopped! Press enter to continue ..."
      ;;
    23 )
      result=$(while true; do /usr/bin/php /workspace/magento2gitpod/bin/magento cron:run >> /workspace/magento2gitpod/var/log/cron.log && /usr/bin/php /workspace/magento2gitpod/update/cron.php >> /workspace/magento2gitpod/var/log/cron.log && /usr/bin/php /workspace/magento2gitpod/bin/magento setup:cron:run >> /workspace/magento2gitpod/var/log/cron.log; sleep 60; done &)
      display_result "Magento 2 Cron service started successfully. Press enter to continue ..."
      ;;
    24 )
      result=$(cd /workspace/magento2gitpod; bash pwa-studio-installer.sh)
      display_result "PWA Studio installed successfully. You can start service with bash /workspace/magento2gitpod/pwa/start.sh & Press enter to continue ..."
      ;;
    25 )
      cd /workspace/magento2gitpod; bash cloudbeaver.sh;
      display_result "CloudBeaver installed successfully. You can view SQL tool on port 8003. Press enter to continue ..."
      ;;
    26 )
      cd /workspace/magento2gitpod; bash mailhog.sh;
      display_result "MailHog SMTP server installed successfully. You can view SQL tool on port 8025. Press enter to continue ..."
      ;;
    27 )
      cd /workspace/magento2gitpod; bash switch-php73.sh;
      display_result "Version successfully switched to PHP 7.3 Press enter to continue ..."
      ;;
    28 )
      cd /workspace/magento2gitpod; bash switch-php81.sh; sleep 10; clear
      display_result "Version successfully switched to PHP 8.1 Press enter to continue ..."
      sudo service supervisor start &>/dev/null &
      ;;
    29 )
      cd /workspace/magento2gitpod; bash switch-mysql8.sh;
      display_result "Version successfully switched to MySQL 8 Press enter to continue ..."
      ;;
    30 )
      sudo apt-get update;
      sudo apt-get install varnish -y;
      sudo rm -f /etc/varnish;
      sudo cp /workspace/magento2gitpod/default.vcl /etc/varnish;
      sudo service nginx stop;
      sudo ps aux | grep nginx | awk {'print $2'} | xargs kill -s 9;
      sudo rm -f /etc/nginx/nginx.conf;
      sudo cp /workspace/magento2gitpod/nginx-varnish.conf /etc/nginx/nginx.conf;
      n98-magerun2 config:set system/full_page_cache/caching_application 2;
      n98-magerun2 config:set system/full_page_cache/ttl 86400;
      n98-magerun2 config:set system/full_page_cache/varnish/backend_host 127.0.0.1;
      php bin/magento setup:config:set --http-cache-hosts=127.0.0.1;
      sudo service nginx restart &
      sudo varnishd -F -T :6082 -t 120 -f /etc/varnish/default.vcl -s file,/etc/varnish/varnish.cache,1024M -p pipe_timeout=7200 -p default_ttl=3600 -p thread_pool_max=1000 -p default_grace=3600 -p vcc_allow_inline_c=on -p thread_pool_min=50 -p workspace_client=512k -p thread_pool_timeout=120 -p http_resp_hdr_len=32k -p feature=+esi_ignore_other_elements &
      display_result "Varnish 6 successfully configured and started. Press enter to continue ..."
      ;;
    31 )
      sudo apt-get update;
      sudo apt install debian-archive-keyring curl gnupg apt-transport-https -y;
      sudo rm -f /etc/apt/trusted.gpg.d/varnish.gpg;
      sudo curl -fsSL https://packagecloud.io/varnishcache/varnish71/gpgkey|sudo gpg --always-trust --dearmor -o /etc/apt/trusted.gpg.d/varnish.gpg;
      echo "deb https://packagecloud.io/varnishcache/varnish71/ubuntu/ focal main" | sudo tee /etc/apt/sources.list.d/varnishcache_varnish71.list
      sudo apt-get update;
      sudo apt-get install varnish -y;
      sudo rm -f /etc/varnish;
      sudo cp /workspace/magento2gitpod/default.vcl /etc/varnish;
      sudo service nginx stop;
      sudo ps aux | grep nginx | awk {'print $2'} | xargs kill -s 9;
      sudo rm -f /etc/nginx/nginx.conf;
      sudo cp /workspace/magento2gitpod/nginx-varnish.conf /etc/nginx/nginx.conf;
      n98-magerun2 config:set system/full_page_cache/caching_application 2;
      n98-magerun2 config:set system/full_page_cache/ttl 86400;
      n98-magerun2 config:set system/full_page_cache/varnish/backend_host 127.0.0.1;
      php bin/magento setup:config:set --http-cache-hosts=127.0.0.1;
      sudo service nginx restart &
      sudo varnishd -F -T :6082 -t 120 -f /etc/varnish/default.vcl -s file,/etc/varnish/varnish.cache,1024M -p pipe_timeout=7200 -p default_ttl=3600 -p thread_pool_max=1000 -p default_grace=3600 -p vcc_allow_inline_c=on -p thread_pool_min=50 -p workspace_client=512k -p thread_pool_timeout=120 -p http_resp_hdr_len=32k -p feature=+esi_ignore_other_elements &
      display_result "Varnish 7 successfully configured and started. Press enter to continue ..."
      ;;   
    32 )
      sudo service nginx stop;
      sudo ps aux | grep nginx | awk {'print $2'} | xargs kill -s 9;
      sudo rm -f /etc/nginx/nginx.conf;
      sudo cp /workspace/magento2gitpod/nginx.conf /etc/nginx/nginx.conf;
      n98-magerun2 config:set system/full_page_cache/caching_application 1;
      n98-magerun2 config:set system/full_page_cache/ttl 86400;
      sudo service nginx restart &
      display_result "Varnish 6 or 7 successfully stopped. Press enter to continue ..."
      ;; 
  esac
done
