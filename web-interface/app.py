from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit
import subprocess
import threading

app = Flask(__name__)
socketio = SocketIO(app, async_mode='gevent')

def run_script(command_key, sid):
    commands = {
        'system_info': 'echo "Hostname: $HOSTNAME"; uptime',
        'disk_space': 'df -h',
        'home_space': 'if [[ $(id -u) -eq 0 ]]; then du -sh /home/* 2> /dev/null; else du -sh $HOME 2> /dev/null; fi',
        'install_magento_2.4.7': 'sed -i "s#composer create-project --no-interaction --no-progress --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.7#composer create-project --no-interaction --no-progress --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.7#g" m2-install.sh && chmod a+rwx m2-install.sh && ./m2-install.sh && clear && url=$(gp url | awk -F"//" \'{print $2}\') && url+="/" && url="https://8002-"$url; echo $url',
        'install_magento_2.4.6_p6': 'chmod a+rwx m2-install.sh && ./m2-install.sh && clear && url=$(gp url | awk -F"//" \'{print $2}\') && url+="/" && url="https://8002-"$url; echo $url',
        'install_magento_2.4_dev': 'chmod a+rwx m2-install-solo.sh && ./m2-install-solo.sh && clear && url=$(gp url | awk -F"//" \'{print $2}\') && url+="/" && url="https://8002-"$url; echo $url',
        'install_baler': 'git clone https://github.com/magento/baler.git && cd baler && npm install && npm run build; alias baler="/workspace/magento2gitpod/baler/bin/baler"',
        'install_magepack': 'cd /workspace/magento2gitpod && /usr/bin/php -dmemory_limit=20000M /usr/bin/composer require creativestyle/magesuite-magepack && n98-magerun2 setup:upgrade && n98-magerun2 setup:di:compile && n98-magerun2 setup:static-content:deploy && n98-magerun2 cache:clean && n98-magerun2 cache:flush && nvm install 14.5.0 && npm install -g magepack',
        'start_redis': 'redis-server &',
        'stop_redis': 'ps aux | grep redis | awk \'{print $2}\' | xargs kill -s 9',
        'start_elasticsearch': '$ES_HOME/bin/elasticsearch -d -p $ES_HOME/pid -Ediscovery.type=single-node &',
        'stop_elasticsearch': 'ps aux | grep elastic | awk \'{print $2}\' | xargs kill -s 9',
        'start_blackfire': 'chmod a+rwx ./blackfire-run.sh && ./blackfire-run.sh',
        'stop_blackfire': 'ps aux | grep blackfire | awk \'{print $2}\' | xargs kill -s 9',
        'start_newrelic': 'newrelic-daemon -c /etc/newrelic/newrelic.cfg &',
        'stop_newrelic': 'ps aux | grep newrelic | awk \'{print $2}\' | xargs kill -s 9',
        'start_tideways': '/usr/bin/tideways-daemon --address 0.0.0.0:9135 &',
        'stop_tideways': 'ps aux | grep tideways | awk \'{print $2}\' | xargs kill -s 9',
        'start_xdebug': 'sudo apt-get update; sudo apt-get install -y php7.4-dev; rm -f /etc/php/7.4/mods-available/xdebug.ini && wget http://xdebug.org/files/xdebug-2.9.8.tgz && tar -xvf xdebug-2.9.8.tgz && cd xdebug-2.9.8 && phpize && ./configure --with-php-config=/usr/bin/php-config7.4 && make && clear && echo "xdebug.remote_autostart=on" >> /etc/php/7.4/mods-available/xdebug.ini; echo "xdebug.profiler_enable=On" >> /etc/php/7.4/mods-available/xdebug.ini; echo "xdebug.remote_enable=1" >> /etc/php/7.4/mods-available/xdebug.ini; echo "xdebug.remote_port=9003" >> /etc/php/7.4/mods-available/xdebug.ini; echo "xdebug.profiler_output_name = nemanja.log" >> /etc/php/7.4/mods-available/xdebug.ini; echo "xdebug.show_error_trace=On" >> /etc/php/7.4/mods-available/xdebug.ini; echo "xdebug.show_exception_trace=On" >> /etc/php/7.4/mods-available/xdebug.ini; echo "zend_extension=/workspace/magento2gitpod/xdebug-2.9.8/modules/xdebug.so" >> /etc/php/7.4/mods-available/xdebug.ini; ln -s /etc/php/7.4/mods-available/xdebug.ini /etc/php/7.4/fpm/conf.d/20-xdebug.ini; ln -s /etc/php/7.4/mods-available/xdebug.ini /etc/php/7.4/cli/conf.d/20-xdebug.ini; service php7.4-fpm reload; clear',
        'stop_xdebug': 'echo "Configuring xDebug PHP settings" && echo "xdebug.remote_autostart=off" >> /etc/php/7.4/mods-available/xdebug.ini; echo "xdebug.profiler_enable=Off" >> /etc/php/7.4/mods-available/xdebug.ini; echo "xdebug.remote_enable=0" >> /etc/php/7.4/mods-available/xdebug.ini; echo "xdebug.remote_port=9003" >> /etc/php/7.4/mods-available/xdebug.ini; echo "xdebug.profiler_output_name = nemanja.log" >> /etc/php/7.4/mods-available/xdebug.ini; echo "xdebug.show_error_trace=Off" >> /etc/php/7.4/mods-available/xdebug.ini; echo "xdebug.show_exception_trace=Off" >> /etc/php/7.4/mods-available/xdebug.ini; mv /etc/php/7.4/fpm/conf.d/20-xdebug.ini /etc/php/7.4/fpm/conf.d/20-xdebug.ini-bak; mv /etc/php/7.4/cli/conf.d/20-xdebug.ini /etc/php/7.4/cli/conf.d/20-xdebug.ini-bak; service php7.4-fpm reload',
        'start_xdebug_2.9.7': 'sudo apt-get update; sudo apt-get install -y php7.3-dev; rm -f /etc/php/7.3/mods-available/xdebug.ini && wget http://xdebug.org/files/xdebug-2.9.7.tgz && tar -xvf xdebug-2.9.7.tgz && cd xdebug-2.9.7 && phpize && ./configure --with-php-config=/usr/bin/php-config7.3 && make && clear && echo "xdebug.remote_autostart=on" >> /etc/php/7.3/mods-available/xdebug.ini; echo "xdebug.profiler_enable=On" >> /etc/php/7.3/mods-available/xdebug.ini; echo "xdebug.remote_enable=1" >> /etc/php/7.3/mods-available/xdebug.ini; echo "xdebug.remote_port=9003" >> /etc/php/7.3/mods-available/xdebug.ini; echo "xdebug.profiler_output_name = nemanja.log" >> /etc/php/7.3/mods-available/xdebug.ini; echo "xdebug.show_error_trace=On" >> /etc/php/7.3/mods-available/xdebug.ini; echo "xdebug.show_exception_trace=On" >> /etc/php/7.3/mods-available/xdebug.ini; echo "zend_extension=/workspace/magento2gitpod/xdebug-2.9.7/modules/xdebug.so" >> /etc/php/7.3/mods-available/xdebug.ini; ln -s /etc/php/7.3/mods-available/xdebug.ini /etc/php/7.3/fpm/conf.d/20-xdebug.ini; ln -s /etc/php/7.3/mods-available/xdebug.ini /etc/php/7.3/cli/conf.d/20-xdebug.ini; service php7.3-fpm reload; clear',
        'stop_xdebug_2.9.7': 'echo "Configuring xDebug PHP settings" && echo "xdebug.remote_autostart=off" >> /etc/php/7.3/mods-available/xdebug.ini; echo "xdebug.profiler_enable=Off" >> /etc/php/7.3/mods-available/xdebug.ini; echo "xdebug.remote_enable=0" >> /etc/php/7.3/mods-available/xdebug.ini; echo "xdebug.remote_port=9003" >> /etc/php/7.3/mods-available/xdebug.ini; echo "xdebug.profiler_output_name = nemanja.log" >> /etc/php/7.3/mods-available/xdebug.ini; echo "xdebug.show_error_trace=Off" >> /etc/php/7.3/mods-available/xdebug.ini; echo "xdebug.show_exception_trace=Off" >> /etc/php/7.3/mods-available/xdebug.ini; mv /etc/php/7.3/fpm/conf.d/20-xdebug.ini /etc/php/7.3/fpm/conf.d/20-xdebug.ini-bak; mv /etc/php/7.3/cli/conf.d/20-xdebug.ini /etc/php/7.3/cli/conf.d/20-xdebug.ini-bak; service php7.3-fpm reload',
        'start_cron': 'while true; do /usr/bin/php /workspace/magento2gitpod/bin/magento cron:run >> /workspace/magento2gitpod/var/log/cron.log && /usr/bin/php /workspace/magento2gitpod/update/cron.php >> /workspace/magento2gitpod/var/log/cron.log && /usr/bin/php /workspace/magento2gitpod/bin/magento setup:cron:run >> /workspace/magento2gitpod/var/log/cron.log; sleep 60; done &',
        'install_pwa_studio': 'cd /workspace/magento2gitpod; bash pwa-studio-installer.sh',
        'install_cloudbeaver': 'cd /workspace/magento2gitpod; bash cloudbeaver.sh',
        'install_mailhog': 'cd /workspace/magento2gitpod; bash mailhog.sh',
        'switch_php_7.3': 'cd /workspace/magento2gitpod; bash switch-php73.sh',
        'switch_php_8.1': 'cd /workspace/magento2gitpod; bash switch-php81.sh; sleep 10; clear; sudo service supervisor start &>/dev/null &',
        'switch_php_8.2': 'cd /workspace/magento2gitpod; bash switch-php82.sh; sleep 10; clear; sudo service supervisor start &>/dev/null &',
        'switch_php_8.3': 'cd /workspace/magento2gitpod; bash switch-php83.sh; sleep 10; clear; sudo service supervisor start &>/dev/null &',
        'switch_mysql_8': 'cd /workspace/magento2gitpod && sudo bash switch-mysql8.sh',
        'start_varnish_6': 'sudo apt-get update; sudo apt-get install varnish -y; sudo rm -f /etc/varnish; sudo cp /workspace/magento2gitpod/default.vcl /etc/varnish; sudo service nginx stop; sudo ps aux | grep nginx | awk \'{print $2}\' | xargs kill -s 9; sudo rm -f /etc/nginx/nginx.conf; sudo cp /workspace/magento2gitpod/nginx-varnish.conf /etc/nginx/nginx.conf; n98-magerun2 config:set system/full_page_cache/caching_application 2; n98-magerun2 config:set system/full_page_cache/ttl 86400; n98-magerun2 config:set system/full_page_cache/varnish/backend_host 127.0.0.1; php bin/magento setup:config:set --http-cache-hosts=127.0.0.1; sudo service nginx restart & sudo varnishd -F -T :6082 -t 120 -f /etc/varnish/default.vcl -s file,/etc/varnish/varnish.cache,1024M -p pipe_timeout=7200 -p default_ttl=3600 -p thread_pool_max=1000 -p default_grace=3600 -p vcc_allow_inline_c=on -p thread_pool_min=50 -p workspace_client=512k -p thread_pool_timeout=120 -p http_resp_hdr_len=32k -p feature=+esi_ignore_other_elements &',
        'start_varnish_7': 'sudo apt-get update; sudo apt install debian-archive-keyring curl gnupg apt-transport-https -y; sudo rm -f /etc/apt/trusted.gpg.d/varnish.gpg; sudo curl -fsSL https://packagecloud.io/varnishcache/varnish71/gpgkey|sudo gpg --always-trust --dearmor -o /etc/apt/trusted.gpg.d/varnish.gpg; echo "deb https://packagecloud.io/varnishcache/varnish71/ubuntu/ focal main" | sudo tee /etc/apt/sources.list.d/varnishcache_varnish71.list; sudo apt-get update; sudo apt-get install varnish -y; sudo rm -f /etc/varnish; sudo cp /workspace/magento2gitpod/default.vcl /etc/varnish; sudo service nginx stop; sudo ps aux | grep nginx | awk \'{print $2}\' | xargs kill -s 9; sudo rm -f /etc/nginx/nginx.conf; sudo cp /workspace/magento2gitpod/nginx-varnish.conf /etc/nginx/nginx.conf; n98-magerun2 config:set system/full_page_cache/caching_application 2; n98-magerun2 config:set system/full_page_cache/ttl 86400; n98-magerun2 config:set system/full_page_cache/varnish/backend_host 127.0.0.1; php bin/magento setup:config:set --http-cache-hosts=127.0.0.1; sudo service nginx restart & sudo varnishd -F -T :6082 -t 120 -f /etc/varnish/default.vcl -s file,/etc/varnish/varnish.cache,1024M -p pipe_timeout=7200 -p default_ttl=3600 -p thread_pool_max=1000 -p default_grace=3600 -p vcc_allow_inline_c=on -p thread_pool_min=50 -p workspace_client=512k -p thread_pool_timeout=120 -p http_resp_hdr_len=32k -p feature=+esi_ignore_other_elements &',
        'stop_varnish': 'sudo service nginx stop; sudo ps aux | grep nginx | awk \'{print $2}\' | xargs kill -s 9; sudo rm -f /etc/nginx/nginx.conf; sudo cp /workspace/magento2gitpod/nginx.conf /etc/nginx/nginx.conf; n98-magerun2 config:set system/full_page_cache/caching_application 1; n98-magerun2 config:set system/full_page_cache/ttl 86400; sudo service nginx restart &'
    }

    if command_key in commands:
        command = commands[command_key]
        try:
            if command_key == 'switch_mysql_8':
                result = subprocess.run(command, shell=True)
                output = "Interactive process finished"
            else:
                result = subprocess.run(command, shell=True, capture_output=True, text=True)
                output = result.stdout + result.stderr
            if result.returncode == 0:
                socketio.emit('process_complete', {'output': f'Process completed successfully.\n{output}'}, room=sid)
            else:
                socketio.emit('process_error', {'output': f'Error: {output}'}, room=sid)
        except Exception as e:
            socketio.emit('process_error', {'output': f'Exception: {str(e)}'}, room=sid)
    else:
        socketio.emit('process_error', {'output': 'Invalid command'}, room=sid)

@app.route('/')
def index():
    return '''
        <h1>Magento 2 Gitpod Manager</h1>
        <div id="button-container" style="display: flex; flex-wrap: wrap; gap: 10px;">
            <button onclick="startProcess('system_info')">System Info</button>
            <button onclick="startProcess('disk_space')">Disk Space</button>
            <button onclick="startProcess('home_space')">Home Space</button>
            <button onclick="startProcess('install_magento_2.4.7')">Install Magento 2.4.7</button>
            <button onclick="startProcess('install_magento_2.4.6_p6')">Install Magento 2.4.6-p6</button>
            <button onclick="startProcess('install_magento_2.4_dev')">Install Magento 2.4-dev</button>
            <button onclick="startProcess('install_baler')">Install Baler</button>
            <button onclick="startProcess('install_magepack')">Install MagePack</button>
            <button onclick="startProcess('start_redis')">Start Redis</button>
            <button onclick="startProcess('stop_redis')">Stop Redis</button>
            <button onclick="startProcess('start_elasticsearch')">Start ElasticSearch</button>
            <button onclick="startProcess('stop_elasticsearch')">Stop ElasticSearch</button>
            <button onclick="startProcess('start_blackfire')">Start Blackfire</button>
            <button onclick="startProcess('stop_blackfire')">Stop Blackfire</button>
            <button onclick="startProcess('start_newrelic')">Start Newrelic</button>
            <button onclick="startProcess('stop_newrelic')">Stop Newrelic</button>
            <button onclick="startProcess('start_tideways')">Start Tideways</button>
            <button onclick="startProcess('stop_tideways')">Stop Tideways</button>
            <button onclick="startProcess('start_xdebug')">Start xDebug</button>
            <button onclick="startProcess('stop_xdebug')">Stop xDebug</button>
            <button onclick="startProcess('start_xdebug_2.9.7')">Start xDebug 2.9.7</button>
            <button onclick="startProcess('stop_xdebug_2.9.7')">Stop xDebug 2.9.7</button>
            <button onclick="startProcess('start_cron')">Start Cron</button>
            <button onclick="startProcess('install_pwa_studio')">Install PWA Studio</button>
            <button onclick="startProcess('install_cloudbeaver')">Install CloudBeaver</button>
            <button onclick="startProcess('install_mailhog')">Install MailHog</button>
            <button onclick="startProcess('switch_php_7.3')">Switch to PHP 7.3</button>
            <button onclick="startProcess('switch_php_8.1')">Switch to PHP 8.1</button>
            <button onclick="startProcess('switch_php_8.2')">Switch to PHP 8.2</button>
            <button onclick="startProcess('switch_php_8.3')">Switch to PHP 8.3</button>
            <button onclick="startProcess('switch_mysql_8')">Switch to MySQL 8</button>
            <button onclick="startProcess('start_varnish_6')">Start Varnish 6</button>
            <button onclick="startProcess('start_varnish_7')">Start Varnish 7</button>
            <button onclick="startProcess('stop_varnish')">Stop Varnish</button>
        </div>
        <div id="output" style="border:1px solid #000; padding: 10px; margin-top: 20px;"></div>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.0.0/socket.io.js"></script>
        <script>
            var socket = io();

            function startProcess(command) {
                document.getElementById('output').innerText = 'Process started...';
                socket.emit('start_process', { command: command });
            }

            socket.on('process_complete', function(data) {
                document.getElementById('output').innerText = data.output;
            });

            socket.on('process_error', function(data) {
                document.getElementById('output').innerText = 'Error: ' + data.output;
            });
        </script>
    '''

@socketio.on('start_process')
def handle_start_process(data):
    command = data['command']
    sid = request.sid
    thread = threading.Thread(target=run_script, args=(command, sid))
    thread.start()

if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0')
