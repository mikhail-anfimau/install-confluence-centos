#!/bin/bash

#Colours
#RED="\033[31m"
#GREEN="\033[32m"
#BLUE="\033[34m"
#RESET="\033[0m"

#####################################################################
# Get the inputs from user                                          #
#####################################################################
confluence_user="confluence"
confluence_db="confluence"
http_port="8090"
control_port="8000"

#Java keystore password default value. Default value most certainly hasn't been changed.
keystore_pwd=changeit
###################################################################ee

#general prep
echo -e "\033[32m Install some generic packages\033[0m"
yum update -y
yum install -y  vim wget centos-release-scl

#install required packages
echo -e "\033[32mInstall packages you need for confluence\033[0m"
yum install -y  postgresql-server httpd

#setup database server
postgresql-setup initdb
export PGDATA=/var/lib/pgsql/data
systemctl enable postgresql

#set postgresql to accept connections
sed -i "s|host    all             all             127.0.0.1/32.*|host    all             all             127.0.0.1/32            md5|" /var/lib/pgsql/data/pg_hba.conf  && echo "pg_hba.conf file updated successfully" || echo "failed to update pg_hba.conf"

systemctl start postgresql

mkdir myconf

#prepare database: create database, user and grant permissions to the user
printf "CREATE USER $confluence_user WITH PASSWORD '$confluence_usr_pwd';\nCREATE DATABASE $confluence_db WITH ENCODING='UTF8' OWNER=$confluence_user CONNECTION LIMIT=-1 lc_collate='en_US.utf8' lc_ctype='en_US.utf8' template template0;\nGRANT ALL ON ALL TABLES IN SCHEMA public TO $confluence_user;\nGRANT ALL ON SCHEMA public TO $confluence_user;" > myconf/confluence-db.sql

sudo -u postgres psql -f myconf/confluence-db.sql


#Selinux config mode update to permissive

echo -e "\033[32mFor apache to work properly with ssl, change the mode to permissive\033[0m"
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config && echo SUCCESS || echo FAILURE



#create customised files
cp -v CONF/httpd/confluence.conf myconf/
cp -v CONF/confluence/server.xml myconf/
cp -v CONF/confluence/response.varfile myconf/

#update confluence.conf virtual host file

sed -i "s|confluence.yoursite.com|127.0.0.1|g" myconf/confluence.conf  && echo "server address updated on confluence.conf file successfully" || echo "server address update on confluence.conf failed"
sed -i "s|8090|$http_port|g" myconf/confluence.conf  && echo "server port updated on confluence.conf file successfully" || echo "server port update on confluence.conf failed"

sed -i "s|confluence.yoursite.com|$server_add|g" myconf/server.xml  && echo "server address updated on server.xml file successfully" || echo "server address update on server.xml failed"

mkdir -pv /opt/rh/httpd24/root/var/www/confluence/logs/

#setup apache server
systemctl enable httpd
systemctl start httpd
cp -v myconf/confluence.conf /etc/httpd/conf.d/



#download and prepare confluence
sed -i "s|8090|$http_port|g" myconf/response.varfile  && echo "http port updated on successfully" || echo "server port update on confluence.conf failed"
sed -i "s|8000|$control_port|g" myconf/response.varfile  && echo "control port updated on successfully" || echo "server port update on confluence.conf failed"

mkdir download/

wget -P download/  https://product-downloads.atlassian.com/software/confluence/downloads/atlassian-confluence-$confluence_ver-x64.bin
chmod u+x download/atlassian-confluence-$confluence_ver-x64.bin
sh download/atlassian-confluence-$confluence_ver-x64.bin -q -varfile ../myconf/response.varfile

#copy updated server.xml file
cp -v myconf/server.xml /opt/atlassian/confluence/conf/server.xml

systemctl restart httpd
reboot