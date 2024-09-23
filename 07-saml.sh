#!/bin/bash

MYSQL_HOST=
MYSQL_USER=
MYSQL_PASS=
USERNAME=
PASSWORD=

SETUP_DIR="/tmp/guacamole"
mkdir -p ${SETUP_DIR}
cd ${SETUP_DIR}

curl -fLO https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-sso-1.5.5.tar.gz
tar xzvf guacamole-auth-sso-1.5.5.tar.gz
mv guacamole-auth-sso-1.5.5/saml/guacamole-auth-sso-saml-1.5.5.jar /etc/guacamole/extensions/


# SAML - AAD
cat << EOF | tee -a /etc/guacamole/guacamole.properties
# SAML config
saml-idp-metadata-url: https://login.microsoftonline.com/04db3f8a-ae8b-42e3-88b3-84cb3a2c34aa/federationmetadata/2007-06/federationmetadata.xml?appid=4b18003f-69e9-4fdf-a223-a37d3f38a31e
saml-idp-url: https://login.microsoftonline.com/04db3f8a-ae8b-42e3-88b3-84cb3a2c34aa/saml2
saml-entity-id: https://guac-dev.416corp.ca/
saml-callback-url: https://guac-dev.416corp.ca/guacamole/
saml-strict: false
saml-debug: true
saml-group-attribute: groups
skip-if-unavailable: saml
extension-priority: *, saml
EOF

# Create SAML User
mysql flexibleserverdb \
    --host $MYSQL_HOST \
    --user $MYSQL_USER \
    --password=$MYSQL_PASS << EOF
    -- Generate salt
    SET @salt = UNHEX(SHA2(UUID(), 256));
    -- Create base entity entry for user
    INSERT INTO guacamole_entity (name, type)
    VALUES ('$USERNAME', 'USER');
    -- Create user and hash password with salt
    INSERT INTO guacamole_user (
        entity_id,
        password_salt,
        password_hash,
        password_date
    )
    SELECT
        entity_id,
        @salt,
        UNHEX(SHA2(CONCAT('$PASSWORD', HEX(@salt)), 256)),
        CURRENT_TIMESTAMP
    FROM guacamole_entity
    WHERE
        name = '$USERNAME'
        AND type = 'USER';

EOF

# Create SAML User
mysql flexibleserverdb \
    --host $MYSQL_HOST \
    --user $MYSQL_USER \
    --password=$MYSQL_PASS << EOF
    update guacamole_user_attribute 
    set attribute_value='totpdisabled' 
    where 
        user_id = 3 and 
        attribute_name = 'guac-totp-key-secret';
EOF