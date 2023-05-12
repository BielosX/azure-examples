#!/bin/bash

yum -y install httpd

cat << EOT >> /var/www/html/index.html
<html>
  <body>
    <h1>Hello from Azure Linux VM!</h1>
  </body>
</html>
EOT

systemctl enable httpd
systemctl start httpd