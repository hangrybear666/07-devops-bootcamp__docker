#!/bin/bash

# load key value pairs from config file
source ../.env
source ../config/remote.properties

# read pw for SUDO commands
read -p "Please provide password for user $SERVICE_USER: " SERVICE_USER_PW

# ssh into remote with newly created user to download Java and Gradle 
ssh $SERVICE_USER@$REMOTE_ADDRESS <<EOF

echo $AWS_ECR_LOGIN_PWD | docker login --username AWS --password-stdin $AWS_ECR_URL
echo $SERVICE_USER_PW | sudo -S docker pull $AWS_ECR_URL:1.0

EOF
