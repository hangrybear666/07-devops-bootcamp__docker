#!/bin/bash

# extract the current directory name from pwd command (everything behind the last backslash
CURRENT_DIR=$(pwd | sed 's:.*/::')
if [ "$CURRENT_DIR" != "scripts" ]
then
  echo "please change directory to scripts folder and execute the shell script again."
  exit 1
fi

# load key value pairs from config file
source ../.env
source ../config/remote.properties

# read pw for SUDO commands
read -p "Please provide password for user $SERVICE_USER: " SERVICE_USER_PW
read -p "Please provide node-app version tag: " VERSION_TAG
AWS_ECR_LOGIN_PWD=$(aws ecr get-login-password --region eu-north-1)

# ssh into remote with root user to login to docker, since later docker commands are executed with sudo, requiring auth credentials to be stored in root
ssh $ROOT_USER@$REMOTE_ADDRESS <<EOF
# remove prior auth credentials
rm -f /root/.docker/config.json
echo $AWS_ECR_LOGIN_PWD | docker login --username AWS --password-stdin $AWS_ECR_URL
EOF

# setup file system for deployment
ssh $SERVICE_USER@$REMOTE_ADDRESS <<EOF
cd ~
if [ ! -d "node-app" ]
then
  mkdir node-app
  echo "node-app directory created."
fi

if [ ! -d "node-app/app" ]
then
  cd node-app
  mkdir app
  echo "node-app/app directory created"
fi

#echo $SERVICE_USER_PW | sudo -S docker pull $AWS_ECR_URL:$VERSION_TAG
EOF

# copy docker compose and node-app .env file to remote via scp
cd ..
echo "Copying files via scp..."
scp node-app/docker-compose-remote.yaml $SERVICE_USER@$REMOTE_ADDRESS:~/node-app/
scp node-app/app/.env $SERVICE_USER@$REMOTE_ADDRESS:~/node-app/app/
scp node-app/seed-mongodb.js $SERVICE_USER@$REMOTE_ADDRESS:~/node-app/

# ssh into remote with service user to start the mongo, mongo-express and node app with docker compose
ssh $SERVICE_USER@$REMOTE_ADDRESS <<EOF
cd node-app
# expose the artifact download URL constructed with remote url and version tag
export AWS_NODE_IMG_URL=$AWS_ECR_URL:$VERSION_TAG

# -E flag preserves environment variables through the new sudo environment
echo $SERVICE_USER_PW | sudo -S -E docker compose -f docker-compose-remote.yaml up
EOF
