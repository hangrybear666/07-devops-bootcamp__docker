#!/bin/bash

# load key value pairs from config file
source ../config/remote.properties

PUBLIC_KEY=$(cat $HOME/.ssh/id_rsa.pub)

# ask for user input to avoid password exposure in git
read -p "Please provide password for new user $SERVICE_USER: " SERVICE_USER_PW 

ssh $ROOT_USER@$REMOTE_ADDRESS <<EOF
# reset prior user and the respective home folder
userdel -r $SERVICE_USER

#create new user
useradd -m $SERVICE_USER

# add sudo privileges to service user
sudo cat /etc/sudoers | grep $SERVICE_USER

if [ -z "\$( sudo cat /etc/sudoers | grep $SERVICE_USER )" ]
then
  echo "$SERVICE_USER ALL=(ALL:ALL) ALL" | sudo EDITOR="tee -a" visudo
  echo "$SERVICE_USER added to sudoers file."
else 
  echo "$SERVICE_USER found in sudoers file."
fi

echo "$SERVICE_USER:$SERVICE_USER_PW" | chpasswd

# switch to new user
su - $SERVICE_USER

# add public key to new user's authorized keys
mkdir .ssh
cd .ssh
touch authorized_keys
echo "created .ssh/authorized keys file"
echo "$PUBLIC_KEY" > authorized_keys
echo "added public key to authorized_keys file of new user."
EOF

# ssh into remote with newly created user to download Java and Gradle 
ssh $SERVICE_USER@$REMOTE_ADDRESS <<EOF

# remove prior docker installations
echo $SERVICE_USER_PW | sudo -S dnf remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine

# install docker 
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Installed docker version: \$(docker -v)"
echo "Installed docker compose version: \$(docker compose version)"

#Start docker daemon service
sudo systemctl start docker
EOF

