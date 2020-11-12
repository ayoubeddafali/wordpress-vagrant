#!/bin/bash

mysql_root_password=$1
db_name=$2
db_user=$3
db_password=$4

sudo apt-get update -y 

sed -i -e 's/#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf
service systemd-resolved restart

echo "Installing Mysql.."
# https://serversforhackers.com/c/installing-mysql-with-debconf
debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysql_root_password"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysql_root_password"

apt-get install -y vim mysql-server mysql-client curl

echo "Configuring Mysql.."

cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.default

# Allow access from host machine (digitalquery#21)
sed -i 's/bind-address[[:space:]]\+= 127\.0\.0\.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# https://stackoverflow.com/a/22933056/2603230
echo "[client]
user = root
password = $mysql_root_password
host = localhost
" > ~/.mysql_root.cnf

echo "Starting Mysql Server.."
service mysql restart


# if $db_name is specified, then create the database and user (if neccesary)

if [ ! -z $db_name ] ; then

  echo "**** Creating $db_name Database.."
  mysql --defaults-extra-file=~/.mysql_root.cnf -e "CREATE DATABASE IF NOT EXISTS $db_name;"

  if [ ! -z "$db_user" ]; then
	  echo "**** Adding custom user: $db_user"
      mysql --defaults-extra-file=~/.mysql_root.cnf -e "GRANT ALL ON $db_name.* TO '$db_user'@'%' IDENTIFIED BY '$db_password'"
  fi

else
	echo "**** No database name specified - skipping db creation"
fi
