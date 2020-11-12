#!/bin/bash

wp_version=$1
php_version=$2
wp_path="/mnt/wordpress"

sudo apt-get update

sed -i -e 's/#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf
service systemd-resolved restart

# Install PHP 
add-apt-repository -y ppa:ondrej/php
apt-get update

apt-get install -y php${php_version} 

# Install/Update wp-cli
if [  -f /usr/local/bin/wp ]; then
  echo "**** Updating wp-cli"
  sudo wp cli update --allow-root --yes
else
  echo "**** Installing wp-cli"
  cd ~/
  curl -Os https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  sudo mv wp-cli.phar /usr/local/bin/wp
fi


# wpcli_defaults_folder='/home/vagrant/.wp-cli'
# if [ ! -d $wpcli_defaults_folder  ]; then
#   echo "**** Adding wp-cli defaults"
#   mkdir $wpcli_defaults_folder
#   cp /vagrant/wp-vagrant/wp/wp-cli.config.yml $wpcli_defaults_folder/config.yml
# fi

apt-get install -y nfs-kernel-server

# Create wordpress mount
mkdir -p $wp_path

echo "**** Installing WordPress $wp_version"

# if wp_version is specified, then add this
download_string=""
if [ ! -z $wp_version ]; then
  download_string=" --version="$wp_version
fi

# Remove any restrictions in the directory permissions
chown -R nobody:nogroup $wp_path
chmod 777 $wp_path

# downloading wordpress
[ -f $wp_path/.last_update ] || sudo -u vagrant -i -- wp core download --path=$wp_path $download_string --quiet

# trick to not download wordpress everytime
touch $wp_path/.last_update

# Grant NFS share access
grep -xF "$wp_path  192.168.100.0/24(rw,sync,no_subtree_check)" /etc/exports || echo "$wp_path  192.168.100.0/24(rw,sync,no_subtree_check)" >> /etc/exports

# rw : Read-Write
# sync: Requires changes to be written to the disk before they are applied.
# no_subtree_check: Eliminates subtree checking.

# In more production grade way, we actually should do something like this, and grant access by IP 
# /mnt/wordpress  192.168.100.2 (re,sync,no_subtree_check)

# Export the nfs share directory
exportfs -a
systemctl restart nfs-kernel-server

# In case of active firewall 

ufw allow from 192.168.100.0/16 to any port nfs