#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

SETUP_DIR="/tmp/guacamole"

# update apt
sudo apt-get update 
sudo apt-get -qq upgrade

apt-get install -qq build-essential \
    libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin uuid-dev libossp-uuid-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev \
    tomcat9 tomcat9-admin tomcat9-common tomcat9-user \
    nginx-core mysql-client xmlstarlet \
    netcat-openbsd ca-certificates ghostscript fonts-liberation fonts-dejavu xfonts-terminus 

if [ $? -ne 0 ]; then
    echo "failed to install dependencies"
    exit
fi

mkdir -p ${SETUP_DIR} && cd ${SETUP_DIR}

# guacamole-server
curl --fail --location --remote-name https://downloads.apache.org/guacamole/1.5.5/source/guacamole-server-1.5.5.tar.gz

tar xzvf guacamole-server-1.5.5.tar.gz
cd guacamole-server-1.5.5/
./configure --with-init-dir=/etc/init.d 
make 
make install 
ldconfig
cd ..

# guacamole-client
curl --fail --location --remote-name https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-1.5.5.war
mv guacamole-1.5.5.war /var/lib/tomcat9/webapps/guacamole.war

# restart services
systemctl daemon-reload
systemctl start guacd
systemctl enable guacd
#systemctl restart tomcat9

# rm -r ${SETUP_DIR}