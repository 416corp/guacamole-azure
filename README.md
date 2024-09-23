# Problem

Build remote access gateway with MFA support to access a windows vm from internet using open source Linux products. Remote access must be client less browser based. 


# Solution

Setup Apache Guacamole as a remote access gateway to access windows virtual machines hosted in the cloud. The client VMs are configured without public ip. The solution uses Microsoft Azure public cloud to host the infrastructure.

It is possible to improve availability and scalability using availability group with multiple application servers to be accessed via load balancer. External database is used for higher availability and scalability. 


## Create Azure infrastructure

Will setup resource group, vnet, app server, flexible db server, client windows vm. Create .CONFIG file from .CONFIG.example to set up environment variables.

./01-build-azure-infrastructure.sh

## 2. Register DNS record

Once you create the App server and get the public ip address, register DNS record.

## 3. Install Guacamole Server. 

Will install dependencies and build guacamole-server.

az vm run-command invoke  \
  --resource-group Guac-DEV-RG \
  --name Guac-DEV-APP \
  --command-id RunShellScript \
  --scripts "@03-install-guacamole.sh"

## 4. Configure NGINX proxy

Will configure proxy and setup ssl.

az vm run-command invoke  \
    --resource-group Guac-DEV-RG \
    --name Guac-DEV-APP \
    --command-id RunShellScript \
    --scripts "@04-configure-proxy.sh"

## 5. Configure Guacamole

Will configure guacamole for database auth and totp.

az vm run-command invoke  \
    --resource-group Guac-DEV-RG \
    --name Guac-DEV-APP \
    --command-id RunShellScript \
    --scripts "@05-configure-guacamole.sh"

## 6. Setup Users and Connections

Will create users and connections.

az vm run-command invoke  \
    --resource-group Guac-DEV-RG \
    --name Guac-DEV-APP \
    --command-id RunShellScript \
    --scripts "@06-users-and-connections.sh"

## 7. SAML

Will integrate via SAML with entraid authentication. Breaks with TOTP, so TOTP should be disabled for SAML users.

az vm run-command invoke  \
    --resource-group Guac-DEV-RG \
    --name Guac-DEV-APP \
    --command-id RunShellScript \
    --scripts "@07-saml.sh"
