#!/bin/bash
source .CONFIG

# Create Resource Group
az group create \
    --name $rgName \
    --location canadacentral

# Create VNET
az network vnet create \
    --resource-group $rgName \
    --name $vnetName \
    --address-prefix 10.0.0.0/16

# Create Subnets
az network vnet subnet create \
    --resource-group $rgName \
    --vnet-name $vnetName \
    --address-prefixes 10.0.1.0/24 \
    --name App-Subnet

az network vnet subnet create \
    --resource-group $rgName \
    --vnet-name $vnetName \
    --address-prefixes 10.0.2.0/24 \
    --name DB-Subnet

az network vnet subnet create \
    --resource-group $rgName \
    --vnet-name $vnetName \
    --address-prefixes 10.0.3.0/24 \
    --name Client-Subnet

# Create NSG
az network nsg create \
    --resource-group $rgName \
    --name $nsgName 

# Create Application Server
az vm create \
    --resource-group $rgName \
    --image Ubuntu2204 \
    --size Standard_B1s \
    --vnet-name $vnetName \
    --subnet App-Subnet \
    --admin-username $vmAdmin \
    --generate-ssh-keys \
    --nsg $nsgName \
    --name $name-APP

# Create Database, will also create new private dns zone
az mysql flexible-server create \
    --resource-group $rgName \
    --sku-name Standard_B1ms \
    --tier Burstable \
    --storage-size 40 \
    --storage-auto-grow Enabled \
    --admin-user $mysqladmin \
    --admin-password $mysqlpassword \
    --vnet $vnetName \
    --subnet DB-Subnet \
    --name $name-DB \
    --yes

# Create Client    
az vm create \
    --resource-group $rgName \
    --name client01 \
    --image MicrosoftWindowsDesktop:windows-11:win11-22h2-pro:latest \
    --size Standard_B1s \
    --vnet-name $vnetName \
    --subnet Client-Subnet \
    --public-ip-address "" \
    --admin-username $vmAdmin \
    --admin-password $vmAdminPassword \
    --nsg $nsgName

# Enable SSH - used for debug - not required
az network nsg rule create \
    --resource-group $rgName \
    --nsg-name $nsgName \
    --name "AllowSSH" \
    --access "Allow" \
    --protocol Tcp \
    --direction Inbound \
    --priority 200 \
    --source-address-prefix Internet \
    --source-port-range "*" \
    --destination-address-prefix "*" \
    --destination-port-range 22

# Enable HTTP
az network nsg rule create \
    --resource-group $rgName \
    --nsg-name $nsgName \
    --name "AllowHTTP" \
    --access "Allow" \
    --protocol Tcp \
    --direction Inbound \
    --priority 201 \
    --source-address-prefix Internet \
    --source-port-range "*" \
    --destination-address-prefix "*" \
    --destination-port-range 80

az network nsg rule create \
    --resource-group $rgName \
    --nsg-name $nsgName \
    --name "AllowHTTPS" \
    --access "Allow" \
    --protocol Tcp \
    --direction Inbound \
    --priority 202 \
    --source-address-prefix Internet \
    --source-port-range "*" \
    --destination-address-prefix "*" \
    --destination-port-range 443
