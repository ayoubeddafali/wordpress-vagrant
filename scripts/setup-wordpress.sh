#!/bin/bash

php_version=$1
install_path=$2
nfs_share_ip=$3
db_ip=$4
wp_db_user=$5
wp_db_password=$6
wp_db_name=$7
hostname=$8

apt-get update


sed -i -e 's/#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf
service systemd-resolved restart

add-apt-repository -y ppa:ondrej/php
apt-get update

apt-get install -y nginx php${php_version} php${php_version}-fpm php${php_version}-gd php${php_version}-mysql php${php_version}-cgi php${php_version}-cli php${php_version}-curl php${php_version}-mbstring php${php_version}-xdebug ffmpeg vim git-core mysql-client curl

echo "**** Setting PHP to ${php_version} and copying config files"

# backup existing php.ini
mv /etc/php/${php_version}/fpm/php.ini /etc/php/${php_version}/fpm/php.ini.default

# copy config files to the relevant php version's config
cp /vagrant/php/php.ini  /etc/php/${php_version}/fpm/php.ini
cp /vagrant/php/www.conf /etc/php/${php_version}/fpm/pool.d/

# point to correct .sock file in the nginx v
sed -i "s/%%php_version%%/${php_version}/" /etc/php/${php_version}/fpm/pool.d/www.conf

update-alternatives --set php /usr/bin/php${php_version}

# Configure Internal Nginx on each wordpress server 

# Start after boot
sudo update-rc.d nginx enable

# copy nginx config
cp /vagrant/nginx/nginx.conf /etc/nginx/

# remove default site
if [ -f /etc/nginx/sites-enabled/default ]; then
  rm /etc/nginx/sites-enabled/default
fi
if [ -f /etc/nginx/sites-enabled/default.conf ]; then
  rm /etc/nginx/sites-enabled/default.conf
fi

# copy our site config and symlink it
cp /vagrant/nginx/default.conf /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

# rename vhost server name to hostname
echo "nginx vhost conf..."

sed -i "s/%%hostname%%/${hostname}/" /etc/nginx/sites-enabled/default.conf

# php version for fpm
sed -i "s/%%php_version%%/${php_version}/" /etc/nginx/sites-enabled/default.conf

# Restart Services 

echo "Starting php-fpm service"
service php${php_version}-fpm restart

echo "Starting Nginx service"
service nginx restart

# Install/Update wp-cli
if [ -f /usr/local/bin/wp ]; then
  echo "**** Updating wp-cli"
  sudo wp cli update --allow-root --yes
else
  echo "**** Installing wp-cli"
  cd ~/
  curl -Os https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  sudo mv wp-cli.phar /usr/local/bin/wp
fi

# Mount WordPress Share

apt-get install -y nfs-common

mkdir -p $install_path 
sudo mount $nfs_share_ip:/mnt/wordpress $install_path

cd $install_path

# Create wp-config.php
echo 'creating wp-config.php'
if [ -z "$wp_db_user" ]; then
  wp_db_user='root'
fi
if [ -z "$wp_db_password" ]; then
  wp_db_password='root'
fi
echo "wp core config --path=$install_path --dbname=$wp_db_name --dbuser=$wp_db_user --dbpass=$wp_db_password --dbhost=$db_ip"


[ -f $install_path/wp-config.php ] || sudo -u vagrant -i --  wp core config  --path=$install_path --dbhost=$db_ip --dbname=$wp_db_name --dbuser=$wp_db_user --dbpass=$wp_db_password --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
PHP

# install database
wp core install --allow-root \
                --path=$install_path \
                --url=${hostname} \
                --admin_user=$wp_db_user \
                --admin_password=$wp_db_password \
                --admin_email="admin@wp.com" \
                --title="Wordpress Site" \
                --skip-email


sudo -u vagrant -i -- wp option update home "http://$hostname" --path=$install_path
sudo -u vagrant -i -- wp option update siteurl "http://$hostname" --path=$install_path

