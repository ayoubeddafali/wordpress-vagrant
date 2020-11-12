#!/bin/bash

set -e

echo "192.168.100.2 mysql" >> /etc/hosts
echo "192.168.100.3 wordpress-1" >> /etc/hosts
echo "192.168.100.6 wordpress-2" >> /etc/hosts
echo "192.168.100.4 nfs" >> /etc/hosts
echo "192.168.100.5 wordpress.test" >> /etc/hosts
