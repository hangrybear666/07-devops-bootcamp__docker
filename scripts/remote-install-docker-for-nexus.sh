#!/bin/bash

# load key value pairs from config file
source ../config/remote.properties

PUBLIC_KEY=$(cat $HOME/.ssh/id_rsa.pub)

# ask for user input to avoid password exposure in git
read -p "Please provide password for new user $SERVICE_USER_2: " SERVICE_USER_2_PW 

ssh $ROOT_USER@$REMOTE_ADDRESS_2 <<EOF
# reset prior user and the respective home folder
userdel -r $SERVICE_USER_2

#create new user
useradd -m $SERVICE_USER_2

# add sudo privileges to service user
sudo cat /etc/sudoers | grep $SERVICE_USER_2

# ensure provided password is set for service user
if [ -z "\$( sudo cat /etc/sudoers | grep $SERVICE_USER_2 )" ]
then
  echo "$SERVICE_USER_2 ALL=(ALL:ALL) ALL" | sudo EDITOR="tee -a" visudo
  echo "$SERVICE_USER_2 added to sudoers file."
else 
  echo "$SERVICE_USER_2 found in sudoers file."
fi

# ensure provided password is set for service user
echo "$SERVICE_USER_2:$SERVICE_USER_2_PW" | chpasswd

# switch to new service user
su - $SERVICE_USER_2

# add public key to new user's authorized keys
mkdir .ssh
cd .ssh
touch authorized_keys
echo "created .ssh/authorized keys file"
echo "$PUBLIC_KEY" > authorized_keys
echo "added public key to authorized_keys file of new user."
EOF

# ssh into remote with newly created user to download Docker Engine
ssh $SERVICE_USER_2@$REMOTE_ADDRESS_2 <<EOF

# set sudo credentials for subsequent commands
echo $SERVICE_USER_2_PW | sudo -S ls

# remove prior docker installations
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo -S apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get -y install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  \$(. /etc/os-release && echo "\$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# install docker
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Notify user with installed docker version
echo "Installed docker version: \$(docker -v)"
echo "Installed docker compose version: \$(docker compose version)"

#Start docker daemon service
sudo systemctl start docker
EOF

