wget https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64;
sudo chmod +x mhsendmail_linux_amd64;
sudo mv mhsendmail_linux_amd64 /usr/local/bin/mhsendmail;
sudo sed -i 's/;sendmail_path =/sendmail_path="\/usr\/local\/bin\/mhsendmail --smtp-addr=127.0.0.1:1025"/g' /etc/php/7.4/cli/php.ini;
sudo sed -i 's/;sendmail_path =/sendmail_path="\/usr\/local\/bin\/mhsendmail --smtp-addr=127.0.0.1:1025"/g' /etc/php/7.4/fpm/php.ini;
sudo /etc/init.d/php7.4-fpm reload;
docker run -d -p 8025:8025 -p 1025:1025 mailhog/mailhog
