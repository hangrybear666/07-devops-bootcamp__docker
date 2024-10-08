#!/bin/bash

# load key value pairs from config file
source ../config/remote.properties

# ask for user input to avoid password exposure in git
read -p "Please provide password for new user $SERVICE_USER_2: " SERVICE_USER_2_PW

# ssh into remote with newly created user to download Docker Engine
ssh $SERVICE_USER_2@$REMOTE_ADDRESS_2 <<EOF

# create volume, expose ports and mount volume to nexus-data within the container
echo $SERVICE_USER_2_PW | sudo -S docker volume create --name nexus-data
sudo docker run -d -p 8081:8081 -p 8082:8082 --name nexus -v nexus-data:/nexus-data sonatype/nexus3

EOF

