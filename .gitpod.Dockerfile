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
    && sudo apt-get install -y php7.4-fpm php7.4-common php7.4-cli php7.4-imagick php7.4-gd php7.4-mysql php7.4-pgsql php7.4-imap php-memcached php7.4-mbstring php7.4-xml php7.4-xmlrpc php7.4-soap php7.4-zip php7.4-curl php7.4-bcmath php7.4-sqlite3 php7.4-apcu php7.4-apcu-bc php7.4-intl php-dev php7.4-dev php7.4-xdebug php-redis \
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
 && sudo apt-get clean && rm -rf /var/cache/apt/* /var/lib/apt/lists/* /tmp/* \
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
			echo "percona-server-server-$PERCONA_MAJOR" "$key" password 'nem4540'; \
		done; \
	} | debconf-set-selections; \
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
    && echo "deb http://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list \
    && sudo apt-get update \
    && sudo apt-get install -y blackfire-agent \
    && sudo apt-get install -y blackfire-php

RUN \
    version=$(php -r "echo PHP_MAJOR_VERSION, PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/${version} \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so

COPY blackfire-agent.ini /etc/blackfire/agent
COPY blackfire-php.ini /etc/php/7.4/fpm/conf.d/92-blackfire-config.ini
COPY blackfire-php.ini /etc/php/7.4/cli/conf.d/92-blackfire-config.ini

COPY blackfire-run.sh /blackfire-run.sh

ENTRYPOINT ["/bin/bash", "/blackfire-run.sh"]

#Install Tideways
RUN sudo apt-get update
RUN echo 'deb http://s3-eu-west-1.amazonaws.com/tideways/packages debian main' > /etc/apt/sources.list.d/tideways.list && \
    curl -sS 'https://s3-eu-west-1.amazonaws.com/tideways/packages/EEB5E8F4.gpg' | apt-key add -
RUN DEBIAN_FRONTEND=noninteractive sudo apt-get update && sudo apt-get install -yq tideways-daemon && \
    sudo apt-get autoremove --assume-yes && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
    
ENTRYPOINT ["tideways-daemon","--hostname=tideways-daemon","--address=0.0.0.0:9135"]

RUN echo 'deb http://s3-eu-west-1.amazonaws.com/tideways/packages debian main' > /etc/apt/sources.list.d/tideways.list && \
    curl -sS 'https://s3-eu-west-1.amazonaws.com/tideways/packages/EEB5E8F4.gpg' | apt-key add - && \
    sudo apt-get update && \
    DEBIAN_FRONTEND=noninteractive sudo apt-get -yq install tideways-php && \
    sudo apt-get autoremove --assume-yes && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo 'extension=tideways.so\ntideways.connection=tcp://0.0.0.0:9135\ntideways.api_key=${TIDEWAYS_APIKEY}\n' > /etc/php/7.4/cli/conf.d/40-tideways.ini
RUN echo 'extension=tideways.so\ntideways.connection=tcp://0.0.0.0:9135\ntideways.api_key=${TIDEWAYS_APIKEY}\n' > /etc/php/7.4/fpm/conf.d/40-tideways.ini
RUN rm -f /etc/php/7.4/cli/20-tideways.ini

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
RUN sudo echo "net.core.somaxconn=65536" >> /etc/sysctl.conf

#New Relic
RUN \
  curl -L https://download.newrelic.com/php_agent/release/newrelic-php5-9.17.1.301-linux.tar.gz | tar -C /tmp -zx && \
  export NR_INSTALL_USE_CP_NOT_LN=1 && \
  export NR_INSTALL_SILENT=1 && \
  /tmp/newrelic-php5-*/newrelic-install install && \
  rm -rf /tmp/newrelic-php5-* /tmp/nrinstall* && \
  touch /etc/php/7.4/fpm/conf.d/newrelic.ini && \
  touch /etc/php/7.4/cli/conf.d/newrelic.ini && \
  sed -i \
      -e 's/"REPLACE_WITH_REAL_KEY"/"ba052d5cdafbbce81ed22048d8a004dd285aNRAL"/' \
      -e 's/newrelic.appname = "PHP Application"/newrelic.appname = "magento2gitpod"/' \
      -e 's/;newrelic.daemon.app_connect_timeout =.*/newrelic.daemon.app_connect_timeout=15s/' \
      -e 's/;newrelic.daemon.start_timeout =.*/newrelic.daemon.start_timeout=5s/' \
      /etc/php/7.4/cli/conf.d/newrelic.ini && \
  sed -i \
      -e 's/"REPLACE_WITH_REAL_KEY"/"ba052d5cdafbbce81ed22048d8a004dd285aNRAL"/' \
      -e 's/newrelic.appname = "PHP Application"/newrelic.appname = "magento2gitpod"/' \
      -e 's/;newrelic.daemon.app_connect_timeout =.*/newrelic.daemon.app_connect_timeout=15s/' \
      -e 's/;newrelic.daemon.start_timeout =.*/newrelic.daemon.start_timeout=5s/' \
      /etc/php/7.4/fpm/conf.d/newrelic.ini && \
  sed -i 's|/var/log/newrelic/|/tmp/|g' /etc/php/7.4/fpm/conf.d/newrelic.ini && \
  sed -i 's|/var/log/newrelic/|/tmp/|g' /etc/php/7.4/cli/conf.d/newrelic.ini
     
RUN sudo chown -R gitpod:gitpod /etc/php
RUN sudo chown -R gitpod:gitpod /etc/newrelic
COPY newrelic.cfg /etc/newrelic
RUN sudo rm -f /usr/bin/php
RUN sudo ln -s /usr/bin/php7.4 /usr/bin/php

#NVM support
RUN sudo mkdir -p /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 0.10.33

# Install nvm with node and npm
RUN curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/v$NODE_VERSION/bin:$PATH
RUN chown -R gitpod:gitpod /usr/local/nvm
    
RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.16.tar.gz --output elasticsearch-5.6.16.tar.gz \
    && tar -xzf elasticsearch-5.6.16.tar.gz
ENV ES_HOME56="$HOME/elasticsearch-5.6.16"

RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.8.9.tar.gz --output elasticsearch-6.8.9.tar.gz \
    && tar -xzf elasticsearch-6.8.9.tar.gz
ENV ES_HOME68="$HOME/elasticsearch-6.8.9"

RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.8.0-linux-x86_64.tar.gz --output elasticsearch-7.8.0-linux-x86_64.tar.gz \
    && tar -xzf elasticsearch-7.8.0-linux-x86_64.tar.gz
ENV ES_HOME78="$HOME/elasticsearch-7.8.0"

RUN set -eux; \
	sudo apt-get update; \
	sudo apt-get install -y --no-install-recommends \
# grab gosu for easy step-down from root
		gosu \
	; \
	sudo rm -rf /var/lib/apt/lists/*; \
# verify that the "gosu" binary works
	gosu nobody true

# Default to a PGP keyserver that pgp-happy-eyeballs recognizes, but allow for substitutions locally
ARG PGP_KEYSERVER=keyserver.ubuntu.com
# If you are building this image locally and are getting `gpg: keyserver receive failed: No data` errors,
# run the build with a different PGP_KEYSERVER, e.g. docker build --tag rabbitmq:3.8 --build-arg PGP_KEYSERVER=pgpkeys.eu 3.8/ubuntu
# For context, see https://github.com/docker-library/official-images/issues/4252

ENV OPENSSL_VERSION 1.1.1k
ENV OPENSSL_SOURCE_SHA256="892a0875b9872acd04a9fde79b1f943075d5ea162415de3047c327df33fbaee5"
# https://www.openssl.org/community/omc.html
ENV OPENSSL_PGP_KEY_IDS="0x8657ABB260F056B1E5190839D9C4D26D0E604491 0x5B2545DAB21995F4088CEFAA36CEE4DEB00CFE33 0xED230BEC4D4F2518B9D7DF41F0DB4D21C1D35231 0xC1F33DD8CE1D4CC613AF14DA9195C48241FBF7DD 0x7953AC1FBC3DC8B3B292393ED5E9E43F7DF9EE8C 0xE5E52560DD91C556DDBDA5D02064C53641C25E5D"

ENV OTP_VERSION 24.0.3
# TODO add PGP checking when the feature will be added to Erlang/OTP's build system
# https://erlang.org/pipermail/erlang-questions/2019-January/097067.html
ENV OTP_SOURCE_SHA256="64a70fb19da9c94d11f4e756998a2e91d8c8400d7d72960b15ad544af60ebe45"

# Install dependencies required to build Erlang/OTP from source
# https://erlang.org/doc/installation_guide/INSTALL.html
# autoconf: Required to configure Erlang/OTP before compiling
# dpkg-dev: Required to set up host & build type when compiling Erlang/OTP
# gnupg: Required to verify OpenSSL artefacts
# libncurses5-dev: Required for Erlang/OTP new shell & observer_cli - https://github.com/zhongwencool/observer_cli
RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	sudo apt-get update; \
	sudo apt-get install --yes --no-install-recommends \
		autoconf \
		ca-certificates \
		dpkg-dev \
		gcc \
		g++ \
		gnupg \
		libncurses5-dev \
		make \
		wget \
	; \
	sudo rm -rf /var/lib/apt/lists/*; \
	\
	OPENSSL_SOURCE_URL="https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"; \
	OPENSSL_PATH="/usr/local/src/openssl-$OPENSSL_VERSION"; \
	OPENSSL_CONFIG_DIR=/usr/local/etc/ssl; \
	\
# Required by the crypto & ssl Erlang/OTP applications
	wget --progress dot:giga --output-document "$OPENSSL_PATH.tar.gz.asc" "$OPENSSL_SOURCE_URL.asc"; \
	wget --progress dot:giga --output-document "$OPENSSL_PATH.tar.gz" "$OPENSSL_SOURCE_URL"; \
	export GNUPGHOME="$(mktemp -d)"; \
	for key in $OPENSSL_PGP_KEY_IDS; do \
		gpg --batch --keyserver "$PGP_KEYSERVER" --recv-keys "$key"; \
	done; \
	gpg --batch --verify "$OPENSSL_PATH.tar.gz.asc" "$OPENSSL_PATH.tar.gz"; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"; \
	echo "$OPENSSL_SOURCE_SHA256 *$OPENSSL_PATH.tar.gz" | sha256sum --check --strict -; \
	mkdir -p "$OPENSSL_PATH"; \
	tar --extract --file "$OPENSSL_PATH.tar.gz" --directory "$OPENSSL_PATH" --strip-components 1; \
	\
# Configure OpenSSL for compilation
	cd "$OPENSSL_PATH"; \
# without specifying "--libdir", Erlang will fail during "crypto:supports()" looking for a "pthread_atfork" function that doesn't exist (but only on arm32v7/armhf??)
	debMultiarch="$(dpkg-architecture --query DEB_HOST_MULTIARCH)"; \
# OpenSSL's "config" script uses a lot of "uname"-based target detection...
	MACHINE="$(dpkg-architecture --query DEB_BUILD_GNU_CPU)" \
	RELEASE="4.x.y-z" \
	SYSTEM='Linux' \
	BUILD='???' \
	./config \
		--openssldir="$OPENSSL_CONFIG_DIR" \
		--libdir="lib/$debMultiarch" \
# add -rpath to avoid conflicts between our OpenSSL's "libssl.so" and the libssl package by making sure /usr/local/lib is searched first (but only for Erlang/OpenSSL to avoid issues with other tools using libssl; https://github.com/docker-library/rabbitmq/issues/364)
		-Wl,-rpath=/usr/local/lib \
	; \
# Compile, install OpenSSL, verify that the command-line works & development headers are present
	make -j "$(getconf _NPROCESSORS_ONLN)"; \
	make install_sw install_ssldirs; \
	cd ..; \
	rm -rf "$OPENSSL_PATH"*; \
	ldconfig; \
# use Debian's CA certificates
	rmdir "$OPENSSL_CONFIG_DIR/certs" "$OPENSSL_CONFIG_DIR/private"; \
	ln -sf /etc/ssl/certs /etc/ssl/private "$OPENSSL_CONFIG_DIR"; \
# smoke test
	openssl version; \
	\
	OTP_SOURCE_URL="https://github.com/erlang/otp/releases/download/OTP-$OTP_VERSION/otp_src_$OTP_VERSION.tar.gz"; \
	OTP_PATH="/usr/local/src/otp-$OTP_VERSION"; \
	\
# Download, verify & extract OTP_SOURCE
	mkdir -p "$OTP_PATH"; \
	wget --progress dot:giga --output-document "$OTP_PATH.tar.gz" "$OTP_SOURCE_URL"; \
	echo "$OTP_SOURCE_SHA256 *$OTP_PATH.tar.gz" | sha256sum --check --strict -; \
	tar --extract --file "$OTP_PATH.tar.gz" --directory "$OTP_PATH" --strip-components 1; \
	\
# Configure Erlang/OTP for compilation, disable unused features & applications
# https://erlang.org/doc/applications.html
# ERL_TOP is required for Erlang/OTP makefiles to find the absolute path for the installation
	cd "$OTP_PATH"; \
	export ERL_TOP="$OTP_PATH"; \
	./otp_build autoconf; \
	CFLAGS="$(dpkg-buildflags --get CFLAGS)"; export CFLAGS; \
# add -rpath to avoid conflicts between our OpenSSL's "libssl.so" and the libssl package by making sure /usr/local/lib is searched first (but only for Erlang/OpenSSL to avoid issues with other tools using libssl; https://github.com/docker-library/rabbitmq/issues/364)
	export CFLAGS="$CFLAGS -Wl,-rpath=/usr/local/lib"; \
	hostArch="$(dpkg-architecture --query DEB_HOST_GNU_TYPE)"; \
	buildArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	dpkgArch="$(dpkg --print-architecture)"; dpkgArch="${dpkgArch##*-}"; \
	./configure \
		--host="$hostArch" \
		--build="$buildArch" \
		--disable-dynamic-ssl-lib \
		--disable-hipe \
		--disable-sctp \
		--disable-silent-rules \
		--enable-jit \
		--enable-clock-gettime \
		--enable-hybrid-heap \
		--enable-kernel-poll \
		--enable-shared-zlib \
		--enable-smp-support \
		--enable-threads \
		--with-microstate-accounting=extra \
		--without-common_test \
		--without-debugger \
		--without-dialyzer \
		--without-diameter \
		--without-edoc \
		--without-erl_docgen \
		--without-et \
		--without-eunit \
		--without-ftp \
		--without-hipe \
		--without-jinterface \
		--without-megaco \
		--without-observer \
		--without-odbc \
		--without-reltool \
		--without-ssh \
		--without-tftp \
		--without-wx \
	; \
# Compile & install Erlang/OTP
	make -j "$(getconf _NPROCESSORS_ONLN)" GEN_OPT_FLGS="-O2 -fno-strict-aliasing"; \
	make install; \
	cd ..; \
	rm -rf \
		"$OTP_PATH"* \
		/usr/local/lib/erlang/lib/*/examples \
		/usr/local/lib/erlang/lib/*/src \
	; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	sudo apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	find /usr/local -type f -executable -exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	; \
	sudo apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	\
# Check that OpenSSL still works after purging build dependencies
	openssl version; \
# Check that Erlang/OTP crypto & ssl were compiled against OpenSSL correctly
	erl -noshell -eval 'io:format("~p~n~n~p~n~n", [crypto:supports(), ssl:versions()]), init:stop().'

ENV RABBITMQ_DATA_DIR=/var/lib/rabbitmq
# Create rabbitmq system user & group, fix permissions & allow root user to connect to the RabbitMQ Erlang VM
RUN set -eux; \
	sudo groupadd --gid 999 --system rabbitmq; \
	sudo useradd --uid 999 --system --home-dir "$RABBITMQ_DATA_DIR" --gid rabbitmq rabbitmq; \
	sudo mkdir -p "$RABBITMQ_DATA_DIR" /etc/rabbitmq /etc/rabbitmq/conf.d /tmp/rabbitmq-ssl /var/log/rabbitmq; \
	sudo chown -fR rabbitmq:rabbitmq "$RABBITMQ_DATA_DIR" /etc/rabbitmq /etc/rabbitmq/conf.d /tmp/rabbitmq-ssl /var/log/rabbitmq; \
	sudo chmod 777 "$RABBITMQ_DATA_DIR" /etc/rabbitmq /etc/rabbitmq/conf.d /tmp/rabbitmq-ssl /var/log/rabbitmq; \
	sudo ln -sf "$RABBITMQ_DATA_DIR/.erlang.cookie" /root/.erlang.cookie

# Use the latest stable RabbitMQ release (https://www.rabbitmq.com/download.html)
ENV RABBITMQ_VERSION 3.9.0-rc.1
# https://www.rabbitmq.com/signatures.html#importing-gpg
ENV RABBITMQ_PGP_KEY_ID="0x0A9AF2115F4687BD29803A206B73A36E6026DFCA"
ENV RABBITMQ_HOME=/opt/rabbitmq

# Add RabbitMQ to PATH, send all logs to TTY
ENV PATH=$RABBITMQ_HOME/sbin:$PATH \
	RABBITMQ_LOGS=-

# Install RabbitMQ
RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	sudo apt-get update; \
	sudo apt-get install --yes --no-install-recommends \
		ca-certificates \
		gnupg \
		wget \
		xz-utils \
	; \
	sudo rm -rf /var/lib/apt/lists/*; \
	\
	RABBITMQ_SOURCE_URL="https://github.com/rabbitmq/rabbitmq-server/releases/download/v$RABBITMQ_VERSION/rabbitmq-server-generic-unix-latest-toolchain-$RABBITMQ_VERSION.tar.xz"; \
	RABBITMQ_PATH="/usr/local/src/rabbitmq-$RABBITMQ_VERSION"; \
	\
	wget --progress dot:giga --output-document "$RABBITMQ_PATH.tar.xz.asc" "$RABBITMQ_SOURCE_URL.asc"; \
	wget --progress dot:giga --output-document "$RABBITMQ_PATH.tar.xz" "$RABBITMQ_SOURCE_URL"; \
	\
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$RABBITMQ_PGP_KEY_ID"; \
	gpg --batch --verify "$RABBITMQ_PATH.tar.xz.asc" "$RABBITMQ_PATH.tar.xz"; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"; \
	\
	mkdir -p "$RABBITMQ_HOME"; \
	tar --extract --file "$RABBITMQ_PATH.tar.xz" --directory "$RABBITMQ_HOME" --strip-components 1; \
	rm -rf "$RABBITMQ_PATH"*; \
# Do not default SYS_PREFIX to RABBITMQ_HOME, leave it empty
	grep -qE '^SYS_PREFIX=\$\{RABBITMQ_HOME\}$' "$RABBITMQ_HOME/sbin/rabbitmq-defaults"; \
	sed -i 's/^SYS_PREFIX=.*$/SYS_PREFIX=/' "$RABBITMQ_HOME/sbin/rabbitmq-defaults"; \
	grep -qE '^SYS_PREFIX=$' "$RABBITMQ_HOME/sbin/rabbitmq-defaults"; \
	sudo chown -R rabbitmq:rabbitmq "$RABBITMQ_HOME"; \
	\
	sudo apt-mark auto '.*' > /dev/null; \
	sudo apt-mark manual $savedAptMark; \
	sudo apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	\
# verify assumption of no stale cookies
	[ ! -e "$RABBITMQ_DATA_DIR/.erlang.cookie" ]; \
# Ensure RabbitMQ was installed correctly by running a few commands that do not depend on a running server, as the rabbitmq user
# If they all succeed, it's safe to assume that things have been set up correctly
	gosu rabbitmq rabbitmqctl help; \
	gosu rabbitmq rabbitmqctl list_ciphers; \
	gosu rabbitmq rabbitmq-plugins list; \
# no stale cookies
	rm "$RABBITMQ_DATA_DIR/.erlang.cookie"

# Enable Prometheus-style metrics by default (https://github.com/docker-library/rabbitmq/issues/419)
RUN set -eux; \
	gosu rabbitmq rabbitmq-plugins enable --offline rabbitmq_prometheus; \
	echo 'management_agent.disable_metrics_collector = true' > /etc/rabbitmq/conf.d/management_agent.disable_metrics_collector.conf; \
	chown rabbitmq:rabbitmq /etc/rabbitmq/conf.d/management_agent.disable_metrics_collector.conf

# Added for backwards compatibility - users can simply COPY custom plugins to /plugins
RUN sudo ln -sf /opt/rabbitmq/plugins /plugins

# set home so that any `--user` knows where to put the erlang cookie
ENV HOME $RABBITMQ_DATA_DIR
# Hint that the data (a.k.a. home dir) dir should be separate volume
VOLUME $RABBITMQ_DATA_DIR

# warning: the VM is running with native name encoding of latin1 which may cause Elixir to malfunction as it expects utf8. Please ensure your locale is set to UTF-8 (which can be verified by running "locale" in your shell)
# Setting all environment variables that control language preferences, behaviour differs - https://www.gnu.org/software/gettext/manual/html_node/The-LANGUAGE-variable.html#The-LANGUAGE-variable
# https://docs.docker.com/samples/library/ubuntu/#locales
ENV LANG=C.UTF-8 LANGUAGE=C.UTF-8 LC_ALL=C.UTF-8

COPY lighthouse.conf /etc
RUN sudo cat /etc/lighthouse.conf >> /var/lib/rabbitmq/.bashrc
