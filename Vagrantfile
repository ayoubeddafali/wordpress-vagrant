# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

if File.file?('config.yaml')
  conf = YAML.load_file('config.yaml')
else 
  raise 'Configuration file config.yaml not found'
end 

mysql = conf["mysql"]
nfs = conf["nfs"]
wordpress = conf["wordpress"]
apache = conf["apache2"]


Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"

  # Setup Mysql Server 
  (1..mysql["count"]).each do |i|
    config.vm.define "mysql" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "mysql-#{i}"
        vb.memory = mysql["memory"]
        vb.cpus = mysql["cpus"]
      end 

      node.vm.hostname = "mysql-#{i}"
      node.vm.network :private_network, ip: mysql["ip"]
      node.vm.provision "setup-hosts", type: "shell", :path => "scripts/setup-hosts.sh"
      node.vm.provision "setup-mysql", type: "shell", :path => "scripts/setup-mysql.sh" do |s|
        s.args = ["#{mysql['mysql_root_password']}", "#{mysql['db_name']}", "#{mysql['db_user']}", "#{mysql['db_password']}"]
      end
    end 
  end 

  # Setup NFS Server
  (1..nfs["count"]).each do |i|
    config.vm.define "nfs" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "nfs-#{i}"
        vb.memory = nfs["memory"]
        vb.cpus = nfs["cpus"]
      end 

      node.vm.hostname = "nfs-#{i}"
      node.vm.network :private_network, ip: nfs["ip"]
      node.vm.provision "setup-hosts", type: "shell", :path => "scripts/setup-hosts.sh"
      node.vm.provision "setup-nfs", type: "shell", :path => "scripts/setup-nfs.sh" do |s|
        s.args = ["#{nfs['wordpress_version']}", "#{nfs['php_version']}"]
      end
    end 
  end 

  # Setup Wordpress
  (1..wordpress["count"]).each do |i|
    config.vm.define "wordpress-#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "wordpress-#{i}"
        vb.memory = wordpress["memory"]
        vb.cpus = wordpress["cpus"]
      end 

      node.vm.hostname = "wordpress-#{i}"
      node.vm.network :private_network, ip: wordpress["ip"][i-1]
      # node.vm.network :forwarded_port, guest: 80, host: 33733, name: "vboxnet5"
      node.vm.provision "setup-hosts", type: "shell", :path => "scripts/setup-hosts.sh"
      node.vm.provision "setup-wordpress", type: "shell", :path => "scripts/setup-wordpress.sh" do |s|
        s.args = ["#{wordpress['php_version']}", "#{wordpress['install_path']}", "#{wordpress['nfs_share_ip']}", "#{wordpress['db_ip']}", "#{wordpress['wp_db_user']}", "#{wordpress['wp_db_password']}", "#{wordpress['wp_db_name']}", "#{wordpress['site']}" ]
      end
    end 
  end 

  # Setup Apache
  (1..apache["count"]).each do |i|
    config.vm.define "apache" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "apache-#{i}"
        vb.memory = apache["memory"]
        vb.cpus = apache["cpus"]
      end 

      node.vm.hostname = "wordpress.test"
      node.vm.network :private_network, ip: apache["ip"]
      node.vm.provision "setup-hosts", type: "shell", :path => "scripts/setup-hosts.sh"
      node.vm.provision "setup-apache", type: "shell", :path => "scripts/setup-apache.sh"
    end 
  end 

end
