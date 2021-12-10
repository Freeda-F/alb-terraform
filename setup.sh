#!/bin/bash

sudo yum install httpd git -y

sudo systemctl restart httpd.service
sudo systemctl enable httpd.service

cd /tmp/
sudo git clone https://github.com/Freeda-F/sample-HTML-website.git
sudo cp -pr sample-HTML-website/* /var/www/html
sudo chown -R apache. /var/www/html/

sudo systemctl restart httpd.service