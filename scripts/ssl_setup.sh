#!/bin/bash -l

echo "Setting up SSL"

export RAILS_ENV=$1

## The parameters here are set hard coded instead of getting them as runtime
## arguments because the permissions are very rigid. There is a psecific
## sudoers.d permission for running this script and it can account only for a
## very specific format.
if [ "$RAILS_ENV" = "onpremise" ];then
  export TMP_PATH=/tmp
  export OUT_CERT_PATH=/etc/ssl/certs
  export OUT_KEY_PATH=/etc/ssl/private
  export SSL_PARAMS_FILE=/etc/nginx/snippets/ssl-params.conf
else
  export TMP_PATH=/home/dev/Development/workships/tests
  export OUT_CERT_PATH=/home/dev/Development/workships/tests/out
  export OUT_KEY_PATH=/home/dev/Development/workships/tests/out
  export SSL_PARAMS_FILE=/home/dev/Development/workships/tests/ssl-params.conf
fi

## Get the domain name
cd $TMP_PATH
rm -f RackMultipart*
export CRT_FILE_NAME=`echo *.crt`
export DOMAIN=`echo ${CRT_FILE_NAME:0:-4}`

## Set the final parameter that we need
export IN_CERT_PATH=$TMP_PATH/$DOMAIN.crt
export IN_KEY_PATH=$TMP_PATH/$DOMAIN.key
export OUT_CERT_PATH=$OUT_CERT_PATH/$DOMAIN.crt
export OUT_KEY_PATH=$OUT_KEY_PATH/$DOMAIN.key

echo "Going to run SSL setup with following params:"
echo "DOMAIN: $DOMAIN"
echo "IN_CERT_PATH: $IN_CERT_PATH"
echo "IN_KEY_PATH: $IN_KEY_PATH"
echo "OUT_CERT_PATH: $OUT_CERT_PATH"
echo "OUT_KEY_PATH: $OUT_KEY_PATH"
echo "SSL_PARAMS_FILE: $SSL_PARAMS_FILE"
echo
echo

if [ ! -f "$IN_CERT_PATH" ];then
  echo "Cert file not found in: $IN_CERT_PATH"
  exit 1
fi

if [ ! -f "$IN_KEY_PATH" ];then
  echo "Key file not found in: $IN_KEY_PATH"
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
echo "Update site"
cd /etc/nginx/sites-enabled
rm -f step-ahead.com.conf
ln -s /etc/nginx/sites-available/sa-nginx.conf.ssltemplate $DOMAIN.conf
sed -i -e s/LOCAL_DOMAIN/$DOMAIN/ /etc/nginx/sites-available/sa-nginx.conf.ssltemplate

## Update system SSL setting
echo "Update Rails SSL setting"
sed -i -e "s/config.force_ssl = false/config.force_ssl = true/" /home/app/sa/config/environments/onpremise.rb

## restart nginx
echo "Restart Nginx"
service nginx stop
service nginx start

echo "Done ..."
