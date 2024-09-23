#!/bin/bash

MYSQL_HOST=
MYSQL_USER=
MYSQL_PASS=
SETUP_DIR=

mkdir -p ${SETUP_DIR}
cd ${SETUP_DIR}

# configure guacamole
mkdir -p /etc/guacamole/{extensions,lib}

# database connector
curl -fLO https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-9.0.0.tar.gz
tar xzvf mysql-connector-j-9.0.0.tar.gz
mv mysql-connector-j-9.0.0/mysql-connector-j-9.0.0.jar /etc/guacamole/lib/

# database auth extension
curl -fLO https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-jdbc-1.5.5.tar.gz
tar xzvf guacamole-auth-jdbc-1.5.5.tar.gz
mv guacamole-auth-jdbc-1.5.5/mysql/guacamole-auth-jdbc-mysql-1.5.5.jar /etc/guacamole/extensions/

cat $SETUP_DIR/guacamole-auth-jdbc-1.5.5/mysql/schema/*.sql | mysql flexibleserverdb \
    --host $MYSQL_HOST \
    --user $MYSQL_USER \
    --password=$MYSQL_PASS

# TOTP extension
curl -fLO https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-totp-1.5.5.tar.gz
tar xzvf guacamole-auth-totp-1.5.5.tar.gz
mv guacamole-auth-totp-1.5.5/guacamole-auth-totp-1.5.5.jar /etc/guacamole/extensions/


cat <<EOF | tee /etc/guacamole/guacamole.properties
mysql-hostname: $MYSQL_HOST
mysql-database: flexibleserverdb
mysql-username: $MYSQL_USER
mysql-password: $MYSQL_PASS
mysql-driver: mysql

mysql-user-required: true
mysql-auto-create-accounts: true

mysql-user-password-min-length: 8
mysql-user-password-require-multiple-case: true
mysql-user-password-require-symbol: true
mysql-user-password-require-digit: true
mysql-user-password-prohibit-username: true
mysql-user-password-min-age: 7
mysql-user-password-max-age: 90
mysql-user-password-history-size: 6

mysql-default-max-connections: 1
mysql-default-max-group-connections: 1

topt-mode:      sha256

EOF

chown root.tomcat /etc/guacamole/guacamole.properties
chmod o-r /etc/guacamole/guacamole.properties

# Configure tomcat - set URIEncoding to UTF-9
    # proxyName="lab1.416corp.ca"
    # proxyPort="443"
    # secure="true"
    # scheme="https"

xmlstarlet edit -P --inplace \
    --update "Server/Service[@name=\"Catalina\"]/Connector[@port=\"8080\"]/@URIEncoding" \
    --value "UTF-8" \
    --insert "Server/Service[@name=\"Catalina\"]/Connector[@port=\"8080\"][not(@URIEncoding)]" \
    --type attr \
    -n URIEncoding \
    --value "UTF-8" \
    /etc/tomcat9/server.xml  

# Remote IP Valve
xmlstarlet edit --inplace \
    --subnode "Server/Service[@name=\"Catalina\"]/Engine[@name=\"Catalina\"]/Host[@name=\"localhost\"]" \
    --type elem -n ValveTMP -v "" \
    --insert //ValveTMP -t attr -n className -v "org.apache.catalina.valves.RemoteIpValve" \
    --insert //ValveTMP -t attr -n internalProxies -v "10.0.1.4" \
    --insert //ValveTMP -t attr -n remoteIpHeader -v "x-forwarded-for" \
    --insert //ValveTMP -t attr -n remoteIpProxiesHeader -v "x-forwarded-by" \
    --insert //ValveTMP -t attr -n protocolHeader -v "x-forwarded-proto" \
    --rename //ValveTMP -v Valve \
    /etc/tomcat9/server.xml

systemctl restart tomcat9
systemctl restart guacd

# rm -r ${SETUP_DIR}