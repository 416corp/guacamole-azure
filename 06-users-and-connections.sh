#!/bin/bash

# Create User
MYSQL_HOST=
MYSQL_USER=
MYSQL_PASS=
USERNAME=
PASSWORD=

# reset guacadmin password
mysql flexibleserverdb \
    --host $MYSQL_HOST \
    --user $MYSQL_USER \
    --password=$MYSQL_PASS << EOF

    SET @salt = UNHEX(SHA2(UUID(), 256));
    SET @hash = UNHEX(SHA2(CONCAT('${PASSWORD}', HEX(@salt)), 256));
    UPDATE guacamole_user
    SET
        password_salt = @salt,
        password_hash = @hash
    WHERE entity_id = '1';
EOF

# create second user
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

# create connection
mysql flexibleserverdb \
    --host $MYSQL_HOST \
    --user $MYSQL_USER \
    --password=$MYSQL_PASS << EOF
   
    INSERT INTO guacamole_connection (connection_name, protocol)
    VALUES ('Windows-Client', 'rdp');

    INSERT INTO guacamole_connection_parameter VALUES (1, 'hostname', 'client01');
    INSERT INTO guacamole_connection_parameter VALUES (1, 'ignore-cert', 'true');
    INSERT INTO guacamole_connection_parameter VALUES (1, 'username', '$USERNAME');
    INSERT INTO guacamole_connection_parameter VALUES (1, 'password', '$PASSWORD');

    INSERT INTO guacamole_connection_permission (
        entity_id,
        connection_id,
        permission)
    VALUES (2, 2, 'READ');
EOF


