#!/bin/bash

SERVER_NAME=
ADMIN_EMAIL=

snap install core; snap refresh core; snap install --classic certbot

# configure NGINX proxy and setting up SSL

cat <<EOF | sudo tee /etc/nginx/sites-available/guacamole
server {
    listen 80;
    server_name $SERVER_NAME;

    location /guacamole/ {
        proxy_pass http://localhost:8080;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        access_log off;
    }
}
EOF

ln -s /etc/nginx/sites-available/guacamole /etc/nginx/sites-enabled/guacamole
systemctl restart nginx

certbot --nginx -d $SERVER_NAME -m $ADMIN_EMAIL --agree-tos -n

if [ $? -ne 0 ]; then
    echo "Failed to set up proxy."
    exit
fi

systemctl restart nginx