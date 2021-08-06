#!/bin/bash
# https://magento.github.io/pwa-studio/venia-pwa-concept/setup/
url=$(gp url | awk -F"//" {'print $2'}) && url+="/" && url="https://8002-"$url;
export MAGENTO_BACKEND_URL="${MAGENTO_BACKEND_URL:-${url}}"
export CHECKOUT_BRAINTREE_TOKEN="${CHECKOUT_BRAINTREE_TOKEN:-sandbox_8yrzsvtm_s2bg8fs563crhqzk}"

rm -rf /workspace/magento2gitpod/node_modules
rm -rf /workspace/magento2gitpod/.npm
rm -rf /workspace/magento2gitpod/pwa

export NVM_DIR=/workspace/magento2gitpod/pwa/nvm
mkdir -p $NVM_DIR
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts
npm install yarn -g
npm install rimraf -g

cd /workspace/magento2gitpod/pwa
git clone https://github.com/magento/pwa-studio.git; cd /workspace/magento2gitpod/pwa/pwa-studio; cp -avr .* /workspace/magento2gitpod/pwa; cd /workspace/magento2gitpod/pwa; rm -r -f pwa-studio;
yarn install; yarn buildpack create-env-file packages/venia-concept;
sed -i 's/_SERVER_PORT=0/_SERVER_PORT=10000/g' /workspace/magento2gitpod/pwa/packages/venia-concept/.env
yarn run build
cd /workspace/magento2gitpod/pwa

cat <<EOT > start.sh
#!/bin/bash
export NVM_DIR=/workspace/magento2gitpod/pwa/nvm
. "$NVM_DIR/nvm.sh"
cd /workspace/magento2gitpod/pwa
yarn run stage:venia
EOT
chmod +x start.sh
