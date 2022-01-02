sudo apt-get update;
sudo apt-get install -y curl zip unzip git software-properties-common supervisor sqlite3;
sudo add-apt-repository -y ppa:ondrej/php;
sudo apt-get update;
sudo apt-get install -y php7.3-dev php7.3-fpm php7.3-common php7.3-cli php7.3-imagick php7.3-gd php7.3-mysql php7.3-pgsql php7.3-imap php-memcached php7.3-mbstring php7.3-xml php7.3-xmlrpc php7.3-soap php7.3-zip php7.3-curl php7.3-bcmath php7.3-sqlite3 php7.3-apcu php7.3-apcu-bc php7.3-intl php-dev php7.3-dev php-redis;
sudo php -r "readfile('http://getcomposer.org/installer');" | sudo php -- --install-dir=/usr/bin/ --version=1.10.16 --filename=composer;
sudo mkdir /run/php;
sudo chown gitpod:gitpod /run/php;
sudo chown -R gitpod:gitpod /etc/php;
sudo apt-get remove -y --purge software-properties-common;
sudo apt-get -y autoremove;
sudo apt-get clean;
sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;
sudo update-alternatives --set php /usr/bin/php7.3;
sudo cp php-fpm73.conf /etc/php/7.3/fpm/php-fpm.conf;
sudo chown gitpod:gitpod /tmp/php7.3-fpm.log;
sudo /etc/init.d/php7.4-fpm stop;
sudo /etc/init.d/php7.3-fpm start
