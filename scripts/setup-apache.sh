#!/bin/bash

backend=$1
sed -i -e 's/#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf
service systemd-resolved restart

sudo apt-get update
apt-get install -y apache2

a2enmod proxy
a2enmod proxy_http
a2enmod proxy_balancer
a2enmod lbmethod_byrequests

cp -rfv /vagrant/apache/000-default.conf /etc/apache2/sites-available/000-default.conf

systemctl restart apache2