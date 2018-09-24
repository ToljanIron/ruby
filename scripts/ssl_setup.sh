#!/bin/bash -l

echo "Setting up SSL"

export RAILS_ENV=$1
export DOMAIN=$2

## The parameters here are set hard coded instead of getting them as runtime
## arguments because the permissions are very rigid. There is a psecific
## sudoers.d permission for running this script and it can account only for a
## very specific format.
if [ "$RAILS_ENV" = "onpremise" ];then
  export IN_CERT_PATH=/tmp/$DOMAIN.crt
  export OUT_CERT_PATH=/etc/ssl/certs/$DOMAIN.crt
  export IN_KEY_PATH=/tmp/$DOMAIN.key
  export OUT_KEY_PATH=/etc/ssl/private/$DOMAIN.key
  export SSL_PARAMS_FILE=/etc/nginx/snippets/ssl-params.conf
else
  export IN_CERT_PATH=/home/dev/Development/workships/tests/$DOMAIN.crt
  export OUT_CERT_PATH=/home/dev/Development/workships/tests/out/$DOMAIN.crt
  export IN_KEY_PATH=/home/dev/Development/workships/tests/$DOMAIN.key
  export OUT_KEY_PATH=/home/dev/Development/workships/tests/out/$DOMAIN.key
  export SSL_PARAMS_FILE=/home/dev/Development/workships/tests/ssl-params.conf
fi


if [ ! -f "$IN_CERT_PATH" ];then
  echo "In cert file not found in: $IN_CERT_PATH"
  exit 1
fi

if [ ! -f "$IN_KEY_PATH" ];then
  echo "In key file not found in: $IN_KEY_PATH"
  exit 1
fi

if [ ! -f "$SSL_PARAMS_FILE.template" ];then
  echo "Ssl params file not found in: $SSL_PARAMS_FILE"
  exit 1
fi

## Move files to their correct locations
echo "Moving cert"
cp $IN_CERT_PATH $OUT_CERT_PATH
chown root $OUT_CERT_PATH
chmod 600 $OUT_CERT_PATH

echo "Moving key"
cp $IN_KEY_PATH $OUT_KEY_PATH
chown root $OUT_KEY_PATH
chmod 600 $OUT_KEY_PATH


## Update content of ssl params file
echo "Update ssl-params.conf"
cp $SSL_PARAMS_FILE.template $SSL_PARAMS_FILE
sed -i -e "s+SSL_CERT_FILE+$OUT_CERT_PATH+" $SSL_PARAMS_FILE
sed -i -e "s+SSL_KEY_FILE+$OUT_KEY_PATH+" $SSL_PARAMS_FILE

## Update site
cd etc/nginx/sites-enabled
rm step-ahead.com.conf
ln -s /etc/nginx/sites-available/sa-nginx.conf.ssltemplate $DOMAIN.conf
sed -i -e s/LOCAL_DOMAIN/$DOMAIN/ sa-nginx.conf.ssltemplate

## Update system SSL setting
sed -i -e "s/config.force_ssl = false/config.force_ssl = true/" /home/app/sa/config/environments/onpremise.rb

## restart nginx
service nginx stop
service nginx start


