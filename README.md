# magento2gitpod
Magento 2 optimized setup for https://gitpod.io workspace -- Nginx, MySQL, PHP 7.4, PHP-FPM, and a lot more...

![](magento2gitpod.gif)

Watch full video how you can easily setup Magento 2 Dev environment right in your browser:
https://youtu.be/ZydOkPWJPT8

*How-to instructions:*
1) Register on https://gitpod.io 
2) Fork https://github.com/nemke82/magento2gitpod to your repo
3) Install https://chrome.google.com/webstore/detail/gitpod-online-ide/dodmmooeoklaejobgleioelladacbeki?hl=en
4) Load your forked repo and click on green GITPOD button, next to Clone or Download button:
http://i.imgur.com/XZCn57y.png

Gitpod will now launch a workspace container for you in the cloud, containing a full Linux system. It will also clone the GitHub repository branch based on the GitHub page you were coming from.

More info: https://www.gitpod.io/docs/10_getting_started/

Services/Tools installed:
- **Nginx**
- **PHP 7.4** based on ppa:ondrej/php repo (https://launchpad.net/~ondrej/+archive/ubuntu/php). To add additional PHP extensions, please update https://github.com/nemke82/magento2gitpod/blob/master/.gitpod.Dockerfile#L15 block.
- **Python** (base version)
- **rsync**
- **mc** (Midnight commander)
- **MySQL** (Percona) 5.7 version (latest)
- **xDebug** (latest Magento 2 supported version 2.9.8). From menu area select "Start X-Debug" and wait for confirmation. Enables CLI and PHP together, then you can follow https://www.gitpod.io/docs/languages/php/#debugging-php-in-gitpod guidelines.
- **Blackfire**. Note: Please run **./blackfire-run.sh** to enter your Server/Client ID and Token's. Sometimes it requires extra PHP-FPM restart, so please run service php7.2-fpm restart if required.
- **Tideways**. Note: Please run **/usr/bin/tideways-daemon --address 0.0.0.0:9135 &** to initiate daemon. Please update .env-file located in repo with TIDEWAYS_APIKEY
- **Newrelic**. Note: Please run **newrelic-daemon -c /etc/newrelic/newrelic.cfg** to initiate daemon. Please update .gitpod.Dockerfile (https://github.com/nemke82/magento2gitpod/blob/master/.gitpod.Dockerfile) with license key. Requires Fresh M2 installation (run m2install.sh) or your store to finish process of validation. <BR>
- **Redis**. Note: Please run 'redis-server &' to start it or run it without & in the separate tab.
- **NodeJS/NPM NVM Manager**. Note: run nvm ls-remote to list available versions, then nvm install to install specific version or latest. 
- **ElasticSearch 5.6.16**. Note: Please run following command to start it: <BR>
  '$ES_HOME56/bin/elasticsearch -d -p $ES_HOME56/pid -Ediscovery.type=single-node' <BR>
- **ElasticSearch 6.8.9**. Note: Please run following command to start it: <BR>
  '$ES_HOME68/bin/elasticsearch -d -p $ES_HOME68/pid -Ediscovery.type=single-node' <BR>
- **ElasticSearch 7.8.0**. Note: Please run following command to start it: <BR>
  '$ES_HOME78/bin/elasticsearch -d -p $ES_HOME78/pid -Ediscovery.type=single-node' <BR>
  
  Some extensions like ElasticSuite (https://github.com/Smile-SA/elasticsuite/wiki/ServerConfig-5.x) requires two ElasticSearch plugins to be installed. You can install them with the following commands:<BR>
  
  $ES_HOME/bin/elasticsearch-plugin install analysis-phonetic <BR>
  $ES_HOME/bin/elasticsearch-plugin install analysis-icu <BR>
  
- **MFTF (Magento 2 Multi Functional Testing Framework)** 
Follow https://github.com/magento/magento2-functional-testing-framework/blob/develop/docs/getting-started.md guidelines.
Installer is here: **chmod a+rwx m2-install-solo.sh && bash m2-install-solo.sh**

Note: Please run following command to start Selenium and Chromedriver (as required):

java -Dwebdriver.chrome.driver=chromedriver -jar $HOME/selenium-server-standalone-3.141.59.jar & <BR>
$HOME/chromedriver & <BR>

Every listed service installation code is added within .gitpod.Dockerfile
You can split them into separate workspaces and share it among themself if you know what you are doing.

- **RabbitMQ support**
default username/password: guest/guest <BR>
For browser open 15762 browser (already exposed) <BR>
Rest commands can be used as per RabbitMQ guidelines https://www.rabbitmq.com/cli.html

TO INSTALL Magento 2.4.1 (latest): <BR>
**./m2-install.sh**

For Magento 2.4-dev branch replicated from https://github.com/magento/magento2 please run: <BR>
**m2-install-solo.sh**

MySQL (default settings):
username: root <BR>
password: nem4540 <BR>

In case you need to create additional database: <BR>
mysql -e 'create database nemanja;' <BR>
(where "nemanja" is database name used) <BR>

In case you need to adjust certain my.cnf settings, please edit https://github.com/nemke82/magento2gitpod/blob/master/mysql.cnf file and redeploy GitPod workspace.

**Discovered bugs:**
Sometimes it may happen that the exposed port 8002 used for Nginx does not work when tab is loaded in browser. To fix that, either stop/start workspace or destroy it and start process again. <BR>

If you are moving your own installation don't foget to adjust following cookie paths: <BR>
**web/cookie/path to "/"**
**web/cookie/domain to ".gitpod.io"**
  
You may fork this repo and boot it on your own server or local computer:
https://www.gitpod.io/docs/self-hosted/latest/self-hosted/

**Changelog 2020-07-03:**
- Updated m2-install.sh script to install latest Magento 2.3.5 version
- Support for ElasticSearch 5.6, 6.8 and 7.8
- Menu installer (menu.sh) added.
- Option to start/stop services from menu.sh file added.
- MySQL (my.cnf) file adjusted with new settings.
- NodeJS/NPM NVM Manager.
- Baler installer added based on https://nemanja.io/optimize-magento-2-store-using-baler-method/ article.
- MagePack installer added based on https://nemanja.io/speed-up-magento-2-page-load-rendering-using-magepack-method/ article.
- MySQL switched to Percona 5.7 (latest). Root password defined (it was not previously). Check above for changes.

**Changelog 2020-10-14:**
- PHP 7.2 depreciated and left as optional in the Dockerfile
- PHP 7.3 latest support
- php-fpm.conf file updated to use PHP 7.3 latest

**Changelog 2020-11-03:**
- RabbitMQ Support and integrated to m2-install.sh and m2-install-solo.sh (dev github repo) installations

**Changelog 2020-12-11:**
- Completely rewritten menu.sh file and it's location (now in the editor area) and labeled.
- menu.sh file updated with Magento 2 Loop cron task.
- Added installer for Magento 2.4.1 using composer and Magento 2.4-develop using Git clone ways.

**Changelog 2020-12-15:**
- Command lh added. It provides Google lighhouse report as preview in your Gitpod tab. You can check demo here:
https://youtu.be/vbPi8zzZyBk

**Changelog 2021-04-13:**
- Updated m2-install.sh script to install latest Magento 2.4.2 version

**Changelog 2021-05-13:**
- Added supervisord to the Dockerfile
- MySQL service moved from cold start to supervisord service (type sudo supervisorctl to check all services integrated)

**Changelog 2021-05-26:**
- Default PHP moved to PHP 7.4
