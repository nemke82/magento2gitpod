FROM gitpod/workspace-full:latest

RUN sudo apt-get update
RUN sudo apt-get -y install lsb-release
RUN sudo apt-get -y install apt-utils
RUN sudo apt-get -y install python
RUN sudo apt-get install -y libmysqlclient-dev
RUN sudo apt-get -y install rsync
RUN sudo apt-get -y install curl
RUN sudo apt-get -y install libnss3-dev
RUN sudo apt-get -y install openssh-client
RUN sudo apt-get -y install mc
RUN sudo apt install -y software-properties-common
RUN sudo apt-get -y install gcc make autoconf libc-dev pkg-config
RUN sudo apt-get -y install libmcrypt-dev
RUN sudo mkdir -p /tmp/pear/cache
RUN sudo mkdir -p /etc/bash_completion.d/cargo
RUN sudo apt install -y php-dev
RUN sudo apt install -y php-pear
RUN sudo apt-get -y install dialog

#Install php-fpm7.4
RUN sudo apt-get update \
    && sudo apt-get install -y curl zip unzip git software-properties-common supervisor sqlite3 \
    && sudo add-apt-repository -y ppa:ondrej/php \
    && sudo apt-get update \
    && sudo apt-get install -y php7.4-dev php7.4-fpm php7.4-common php7.4-cli php7.4-imagick php7.4-gd php7.4-mysql php7.4-pgsql php7.4-imap php-memcached php7.4-mbstring php7.4-xml php7.4-xmlrpc php7.4-soap php7.4-zip php7.4-curl php7.4-bcmath php7.4-sqlite3 php7.4-apcu php7.4-apcu-bc php7.4-intl php-dev php7.4-dev php7.4-xdebug php-redis \
    && sudo php -r "readfile('http://getcomposer.org/installer');" | sudo php -- --install-dir=/usr/bin/ --version=1.10.16 --filename=composer \
    && sudo mkdir /run/php \
    && sudo chown gitpod:gitpod /run/php \
    && sudo chown -R gitpod:gitpod /etc/php \
    && sudo apt-get remove -y --purge software-properties-common \
    && sudo apt-get -y autoremove \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && sudo update-alternatives --remove php /usr/bin/php8.0 \
    && sudo update-alternatives --remove php /usr/bin/php7.3 \
    && sudo update-alternatives --set php /usr/bin/php7.4 \
    && sudo echo "daemon off;" >> /etc/nginx/nginx.conf

#Adjust few options for xDebug and disable it by default
RUN echo "xdebug.remote_enable=on" >> /etc/php/7.4/mods-available/xdebug.ini
    #&& echo "xdebug.remote_autostart=on" >> /etc/php/7.4/mods-available/xdebug.ini
    #&& echo "xdebug.profiler_enable=On" >> /etc/php/7.4/mods-available/xdebug.ini \
    #&& echo "xdebug.profiler_output_dir = /workspace/magento2pitpod" >> /etc/php/7.4/mods-available/xdebug.ini \
    #&& echo "xdebug.profiler_output_name = nemanja.log >> /etc/php/7.4/mods-available/xdebug.ini \
    #&& echo "xdebug.show_error_trace=On" >> /etc/php/7.4/mods-available/xdebug.ini \
    #&& echo "xdebug.show_exception_trace=On" >> /etc/php/7.4/mods-available/xdebug.ini
RUN mv /etc/php/7.4/cli/conf.d/20-xdebug.ini /etc/php/7.4/cli/conf.d/20-xdebug.ini-bak
RUN mv /etc/php/7.4/fpm/conf.d/20-xdebug.ini /etc/php/7.4/fpm/conf.d/20-xdebug.ini-bak

# Install MySQL
ENV PERCONA_MAJOR 5.7
RUN sudo apt-get update \
 && sudo apt-get -y install gnupg2 \
 && sudo apt-get clean && sudo rm -rf /var/cache/apt/* /var/lib/apt/lists/* /tmp/* \
 && sudo mkdir /var/run/mysqld \
 && sudo wget -c https://repo.percona.com/apt/percona-release_latest.stretch_all.deb \
 && sudo dpkg -i percona-release_latest.stretch_all.deb \
 && sudo apt-get update

RUN set -ex; \
	{ \
		for key in \
			percona-server-server/root_password \
			percona-server-server/root_password_again \
			"percona-server-server-$PERCONA_MAJOR/root-pass" \
			"percona-server-server-$PERCONA_MAJOR/re-root-pass" \
		; do \
			sudo echo "percona-server-server-$PERCONA_MAJOR" "$key" password 'nem4540'; \
		done; \
	} | sudo debconf-set-selections; \
	sudo apt-get update; \
	sudo apt-get install -y \
		percona-server-server-5.7 percona-server-client-5.7 percona-server-common-5.7 \
	;
	
RUN sudo chown -R gitpod:gitpod /etc/mysql /var/run/mysqld /var/log/mysql /var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring

# Install our own MySQL config
COPY mysql.cnf /etc/mysql/conf.d/mysqld.cnf
COPY .my.cnf /home/gitpod
COPY mysql.conf /etc/supervisor/conf.d/mysql.conf
RUN sudo chown gitpod:gitpod /home/gitpod/.my.cnf

# Install default-login for MySQL clients
COPY client.cnf /etc/mysql/conf.d/client.cnf

#Copy nginx default and php-fpm.conf file
#COPY default /etc/nginx/sites-available/default
COPY php-fpm.conf /etc/php/7.4/fpm/php-fpm.conf
RUN sudo chown -R gitpod:gitpod /etc/php

COPY nginx.conf /etc/nginx

#Selenium required for MFTF
RUN sudo wget -c https://selenium-release.storage.googleapis.com/3.141/selenium-server-standalone-3.141.59.jar
RUN sudo wget -c https://chromedriver.storage.googleapis.com/80.0.3987.16/chromedriver_linux64.zip
RUN sudo unzip chromedriver_linux64.zip

# Install Chrome and Chromium
RUN sudo wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && sudo dpkg -i google-chrome-stable_current_amd64.deb; sudo apt-get -fy install \
    && sudo apt-get install -yq \
       gconf-service libasound2 libatk1.0-0 libatk-bridge2.0-0 libc6 libcairo2 libcups2 libdbus-1-3 \
       libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 \
       libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 \
       libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates \
       fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget

ENV BLACKFIRE_LOG_LEVEL 1
ENV BLACKFIRE_LOG_FILE /var/log/blackfire/blackfire.log
ENV BLACKFIRE_SOCKET unix:///tmp/agent.sock
ENV BLACKFIRE_SOURCEDIR /etc/blackfire
ENV BLACKFIRE_USER gitpod

RUN curl -sS https://packagecloud.io/gpg.key | sudo apt-key add \
    && curl -sS https://packages.blackfire.io/gpg.key | sudo apt-key add \
    && sudo echo "deb http://packages.blackfire.io/debian any main" | sudo tee /etc/apt/sources.list.d/blackfire.list \
    && sudo apt-get update \
    && sudo apt-get install -y blackfire-agent \
    && sudo apt-get install -y blackfire-php

RUN \
    version=$(php -r "echo PHP_MAJOR_VERSION, PHP_MINOR_VERSION;") \
    && sudo curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/${version} \
    && sudo tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && sudo mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so

COPY blackfire-agent.ini /etc/blackfire/agent
COPY blackfire-php.ini /etc/php/7.4/fpm/conf.d/92-blackfire-config.ini
COPY blackfire-php.ini /etc/php/7.4/cli/conf.d/92-blackfire-config.ini

COPY blackfire-run.sh /blackfire-run.sh

ENTRYPOINT ["/bin/bash", "/blackfire-run.sh"]

#Install Tideways
RUN sudo apt-get update
RUN sudo echo 'deb http://s3-eu-west-1.amazonaws.com/tideways/packages debian main' | sudo tee /etc/apt/sources.list.d/tideways.list && \
    sudo curl -sS 'https://s3-eu-west-1.amazonaws.com/tideways/packages/EEB5E8F4.gpg' | sudo apt-key add -
RUN DEBIAN_FRONTEND=noninteractive sudo apt-get update && sudo apt-get install -yq tideways-daemon && \
    sudo apt-get autoremove --assume-yes && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
    
ENTRYPOINT ["tideways-daemon","--hostname=tideways-daemon","--address=0.0.0.0:9135"]

RUN sudo echo 'deb http://s3-eu-west-1.amazonaws.com/tideways/packages debian main' | sudo tee /etc/apt/sources.list.d/tideways.list && \
    sudo curl -sS 'https://s3-eu-west-1.amazonaws.com/tideways/packages/EEB5E8F4.gpg' | sudo apt-key add - && \
    sudo apt-get update && \
    DEBIAN_FRONTEND=noninteractive sudo apt-get -yq install tideways-php && \
    sudo apt-get autoremove --assume-yes && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo 'extension=tideways.so\ntideways.connection=tcp://0.0.0.0:9135\ntideways.api_key=${TIDEWAYS_APIKEY}\n' > /etc/php/7.4/cli/conf.d/40-tideways.ini
RUN echo 'extension=tideways.so\ntideways.connection=tcp://0.0.0.0:9135\ntideways.api_key=${TIDEWAYS_APIKEY}\n' > /etc/php/7.4/fpm/conf.d/40-tideways.ini
RUN sudo rm -f /etc/php/7.4/cli/20-tideways.ini

# Install Redis.
RUN sudo apt-get update \
 && sudo apt-get install -y \
  redis-server \
 && sudo rm -rf /var/lib/apt/lists/*
 
 #n98-magerun2 tool.
 RUN wget https://files.magerun.net/n98-magerun2.phar \
     && chmod +x ./n98-magerun2.phar \
     && sudo mv ./n98-magerun2.phar /usr/local/bin/n98-magerun2
     
#Install APCU
RUN echo "apc.enable_cli=1" > /etc/php/7.4/cli/conf.d/20-apcu.ini
RUN echo "priority=25" > /etc/php/7.4/cli/conf.d/25-apcu_bc.ini
RUN echo "extension=apcu.so" >> /etc/php/7.4/cli/conf.d/25-apcu_bc.ini
RUN echo "extension=apc.so" >> /etc/php/7.4/cli/conf.d/25-apcu_bc.ini

RUN sudo chown -R gitpod:gitpod /var/log/blackfire
RUN sudo chown -R gitpod:gitpod /etc/init.d/blackfire-agent
RUN sudo mkdir -p /var/run/blackfire
RUN sudo chown -R gitpod:gitpod /var/run/blackfire
RUN sudo chown -R gitpod:gitpod /etc/blackfire
RUN sudo chown -R gitpod:gitpod /etc/php
RUN sudo chown -R gitpod:gitpod /etc/nginx
RUN sudo chown -R gitpod:gitpod /etc/init.d/
RUN sudo echo "net.core.somaxconn=65536" | sudo tee /etc/sysctl.conf

#New Relic
RUN \
  curl -L https://download.newrelic.com/php_agent/release/newrelic-php5-9.17.1.301-linux.tar.gz | tar -C /tmp -zx && \
  sudo NR_INSTALL_USE_CP_NOT_LN=1 NR_INSTALL_SILENT=1 /tmp/newrelic-php5-*/newrelic-install install && \
  sudo rm -rf /tmp/newrelic-php5-* /tmp/nrinstall* && \
  sudo touch /etc/php/7.4/fpm/conf.d/newrelic.ini && \
  sudo touch /etc/php/7.4/cli/conf.d/newrelic.ini && \
  sudo sed -i \
      -e 's/"REPLACE_WITH_REAL_KEY"/"ba052d5cdafbbce81ed22048d8a004dd285aNRAL"/' \
      -e 's/newrelic.appname = "PHP Application"/newrelic.appname = "magento2gitpod"/' \
      -e 's/;newrelic.daemon.app_connect_timeout =.*/newrelic.daemon.app_connect_timeout=15s/' \
      -e 's/;newrelic.daemon.start_timeout =.*/newrelic.daemon.start_timeout=5s/' \
      /etc/php/7.4/cli/conf.d/newrelic.ini && \
  sudo sed -i \
      -e 's/"REPLACE_WITH_REAL_KEY"/"ba052d5cdafbbce81ed22048d8a004dd285aNRAL"/' \
      -e 's/newrelic.appname = "PHP Application"/newrelic.appname = "magento2gitpod"/' \
      -e 's/;newrelic.daemon.app_connect_timeout =.*/newrelic.daemon.app_connect_timeout=15s/' \
      -e 's/;newrelic.daemon.start_timeout =.*/newrelic.daemon.start_timeout=5s/' \
      /etc/php/7.4/fpm/conf.d/newrelic.ini && \
  sudo sed -i 's|/var/log/newrelic/|/tmp/|g' /etc/php/7.4/fpm/conf.d/newrelic.ini && \
  sudo sed -i 's|/var/log/newrelic/|/tmp/|g' /etc/php/7.4/cli/conf.d/newrelic.ini
     
RUN sudo chown -R gitpod:gitpod /etc/php
RUN sudo chown -R gitpod:gitpod /etc/newrelic
COPY newrelic.cfg /etc/newrelic
RUN sudo rm -f /usr/bin/php
RUN sudo ln -s /usr/bin/php7.4 /usr/bin/php

# nvm environment variables
RUN sudo mkdir -p /usr/local/nvm
RUN sudo chown gitpod:gitpod /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 14.17.3

# Replace shell with bash so we can source files
RUN sudo rm /bin/sh && sudo ln -s /bin/bash /bin/sh

# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

# install node and npm, set default alias
RUN source $NVM_DIR/nvm.sh \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
    
RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.16.tar.gz --output elasticsearch-5.6.16.tar.gz \
    && tar -xzf elasticsearch-5.6.16.tar.gz
ENV ES_HOME56="$HOME/elasticsearch-5.6.16"

RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.8.9.tar.gz --output elasticsearch-6.8.9.tar.gz \
    && tar -xzf elasticsearch-6.8.9.tar.gz
ENV ES_HOME68="$HOME/elasticsearch-6.8.9"

RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.3-linux-x86_64.tar.gz --output elasticsearch-7.9.3-linux-x86_64.tar.gz \
    && tar -xzf elasticsearch-7.9.3-linux-x86_64.tar.gz
ENV ES_HOME79="$HOME/elasticsearch-7.9.3"

RUN sudo apt-key adv --keyserver "hkps://keys.openpgp.org" --recv-keys "0x0A9AF2115F4687BD29803A206B73A36E6026DFCA" \
    && sudo apt-key adv --keyserver "keyserver.ubuntu.com" --recv-keys "F77F1EDA57EBB1CC" \
    && sudo curl -1sLf 'https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey' | sudo apt-key add - \
    && sudo echo 'deb http://ppa.launchpad.net/rabbitmq/rabbitmq-erlang/ubuntu bionic main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list \
    && sudo echo 'deb-src http://ppa.launchpad.net/rabbitmq/rabbitmq-erlang/ubuntu bionic main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list \
    && sudo echo 'deb https://packagecloud.io/rabbitmq/rabbitmq-server/debian/ buster main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list \
    && sudo echo 'deb-src https://packagecloud.io/rabbitmq/rabbitmq-server/debian/ buster main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list \
    && sudo apt-get update -y \
    && sudo apt-get install -y erlang-base \
       erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
       erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
       erlang-runtime-tools erlang-snmp erlang-ssl \
       erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl

## Install rabbitmq-server and its dependencies
RUN sudo apt-get install rabbitmq-server -y --fix-missing

COPY lighthouse.conf /etc
COPY rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
RUN sudo cat /etc/lighthouse.conf >> /home/gitpod/.bashrc
