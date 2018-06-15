#!/bin/bash
yum update -y
yum install git -y
cd /opt/
git clone https://github.com/mikhail-anfimau/install-confluence-centos.git
cd install-confluence-centos
confluence_usr_pwd="secure_password"
. ./install-confluence.sh