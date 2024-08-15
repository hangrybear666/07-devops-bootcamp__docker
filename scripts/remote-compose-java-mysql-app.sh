#/bin/bash

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
read -p "Please provide java-app version tag: " VERSION_TAG

# setup file system for deployment
ssh $SERVICE_USER@$REMOTE_ADDRESS <<EOF
cd ~
if [ ! -d "java-app" ]
then
  mkdir java-app
  echo "java-app directory created."
fi
EOF

# copy docker compose and java-app .env file to remote via scp
cd ..
echo "Copying files via scp..."
scp exercises/docker-compose-java-app-mysql.yaml $SERVICE_USER@$REMOTE_ADDRESS:~/java-app/
scp exercises/.env $SERVICE_USER@$REMOTE_ADDRESS:~/java-app/

# ssh into remote with root user to login to docker, since later docker commands are executed with sudo, requiring auth credentials to be stored in root
ssh $ROOT_USER@$REMOTE_ADDRESS <<EOF
# remove prior auth credentials
rm -f /root/.docker/config.json
echo $NEXUS_USER_1_PWD | docker login --username $NEXUS_USER_1_ID --password-stdin $REMOTE_ADDRESS_2:8082
EOF

# ssh into remote with service user to start the mysql, phpmyadmin and java app with docker compose
ssh $SERVICE_USER@$REMOTE_ADDRESS <<EOF
cd java-app
# expose env vars created by the user prior
source .env

# expose environment variables not part of .env file
export NEXUS_URL=$REMOTE_ADDRESS_2:8082
export VERSION_TAG=$VERSION_TAG
export DB_PWD=\$MYSQL_PASSWORD

# -E flag preserves environment variables through the new sudo environment
echo $SERVICE_USER_PW | sudo -S -E docker compose -f docker-compose-java-app-mysql.yaml up
EOF

