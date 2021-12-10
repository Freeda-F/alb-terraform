#!/bin/bash

sudo yum install httpd git -y

sudo systemctl restart httpd.service
sudo systemctl enable httpd.service

cd /tmp/
sudo wget https://www.tooplate.com/zip-templates/2126_antique_cafe.zip
sudo unzip 2126_antique_cafe
sudo cp -pr 2126_antique_cafe/* /var/www/html
sudo chown -R apache. /var/www/html/

sudo systemctl restart httpd.service