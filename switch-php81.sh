sudo apt-get -y update;
sudo apt-get install -y curl zip unzip git software-properties-common sqlite3;
sudo add-apt-repository -y ppa:ondrej/php;
sudo apt-get update -y;
sudo apt-get install -y php8.1-dev php8.1-fpm php8.1-common php8.1-cli php8.1-imagick php8.1-gd php8.1-mysql php8.1-pgsql php8.1-imap php-memcached php8.1-mbstring php8.1-xml php8.1-xmlrpc php8.1-soap php8.1-zip php8.1-curl php8.1-bcmath php8.1-sqlite3 php8.1-apcu php8.1-intl php-dev php8.1-dev php-redis;
sudo php -r "readfile('http://getcomposer.org/installer');" | sudo php -- --install-dir=/usr/bin/ --version=2.3.5 --filename=composer;
sudo mkdir /run/php;
sudo chown gitpod:gitpod /run/php;
sudo chown -R gitpod:gitpod /etc/php;
sudo apt-get remove -y --purge software-properties-common;
sudo apt-get -y autoremove;
sudo apt-get clean;
sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;
sudo update-alternatives --set php /usr/bin/php8.1;
sudo cp php-fpm73.conf /etc/php/8.1/fpm/php-fpm.conf
sudo /etc/init.d/php7.4-fpm stop;
sudo supervisorctl stop php-fpm
sudo sed -i 's#pid = /tmp/php7.4-fpm.pid#pid = /tmp/php8.1-fpm.pid#g' /workspace/magento2gitpod/php-fpm.conf
sudo sed -i 's#error_log = /tmp/php7.4-fpm.log#error_log = /tmp/php8.1-fpm.log#g' /workspace/magento2gitpod/php-fpm.conf
sudo sed -i 's#command=/usr/sbin/php-fpm7.4 --fpm-config /workspace/magento2gitpod/php-fpm.conf#command=/usr/sbin/php-fpm8.1 --fpm-config /workspace/magento2gitpod/php-fpm.conf#g' /etc/supervisor/conf.d/sp-php-fpm.conf;
ps aux | grep php-fpm | awk {'print $2'} | xargs kill -s 9;
sudo supervisorctl shutdown mysql;
sudo service supervisor start &
