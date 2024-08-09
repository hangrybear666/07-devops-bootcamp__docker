# Using Docker to Deploy artifacts on remote VPS host machines

Collection of Dockerfiles, docker-compose files and shell scripts for automating web app deployment on remote VPS hosts.

The main packages are:
- A local mongodb, mongo-express and node-js development stack
- A remote nexus repository hosted in a VPS running with java.
- A remote nexus repository hosted in a VPS running as a docker container.
- local docker and docker compose setup
- remote docker and docker compose setup 
- collection of shell scripts to automatically setup and run docker containers on remote hosts.

## Setup

1. Pull SCM

	Pull the repository locally by running 
	```
  	git clone https://github.com/hangrybear666/07-devops-bootcamp__docker.git
	```

2. Create Remote Linux VPS and configure

	Generate local ssh key and add to remote VPS's `authorized_keys` file.

3. Install additional dependencies on remote

	Some Linux distros ship without the `netstat` command we use. In that case run `apt install net-tools` or `dnf install net-tools` on fedora et cetera.

4. Create environment file in node-app/ folder and add secrets
	Add an `.env` file in your repository's `node-app/` directory and add the following key value-pairs:
	```
	MONGO_DB_USERNAME=admin
	MONGO_DB_PWD=xxx
	MONGO_INITDB_ROOT_USERNAME=admin
	MONGO_INITDB_ROOT_PASSWORD=xxx
	ME_CONFIG_MONGODB_ADMINUSERNAME=admin
	ME_CONFIG_MONGODB_ADMINPASSWORD=xxx
	ME_CONFIG_MONGODB_SERVER=mongodb
	ME_CONFIG_MONGODB_URL=mongodb://mongodb:27017
	```

	Add an `.env` file in your repository's root directory and add:
	```
	AWS_ECR_URL="010928217051.dkr.ecr.eu-north-1.amazonaws.com/node-app"

	``` 

5. Add your remote VPS configuration parameters to `config/remote.properties`

	```
	REMOTE_ADDRESS=167.99.128.206
	ROOT_USER="root"
	SERVICE_USER="docker-runner"
	REMOTE_ADDRESS_2=104.248.37.28
	SERVICE_USER_2="nexus-docker-runner"
	```

6. Install docker locally.

	Make sure to install docker and docker-compose (typically built-in) for local development. See https://docs.docker.com/engine/install/

7. Install docker on remote.

	Ensure docker is installed on your remote VPS intended to run the node-app with mongo-db. See https://docs.docker.com/engine/install/

8. Dont forget to open ports in your remote firewall.

	The port 3000 for express server, 8081 for mongo-express and 27017 for mongodb and 22 for ssh.

## Usage (Demo Projects)

1. To run a node-js app, mongodb and mongo-express together in local development with manually configured docker containers

	Execute the following commands in order within the `node-app/` folder.
	```

	# create a bridge network
	docker network create node-mongo-bridge

	# pull and run mongo db 
	docker run -d -p 27017:27017 --env-file app/.env --network node-mongo-bridge --name mongodb -v $(pwd)/seed-mongodb.js:/docker-entrypoint-initdb.d/seed-mongodb.js mongo:latest

	# pull and run mongo express
	docker run -d  -p 8081:8081 --env-file app/.env --network node-mongo-bridge  --name mongo-express  mongo-express

	# build and run app from node-app folder
	docker build -f Dockerfile -t node-app:latest .
	docker run --rm -d --network node-mongo-bridge -p:3000:3000 --env-file app/.env --name node-server node-app

	```

2. To run a node-js app, mongodb and mongo-express together in local development with a simple docker-compose script

	To run these 3 images in the same network, with the desired node-app version simply run in the `node_app/` folder:
	```
	export VERSION_TAG=1.0
	docker compose -f docker-compose.yaml up
	```
	P.S.Mongodb is being initialized with a seed script to create a database and collection via `seed-mongodb.js` automatically, so interaction with mongo-express is not required.

3. To push a docker image to a private AWS Elastic Container Registry, follow these steps

	a. Make sure you create a user without root privileges in AWS IAM.

	b. Then create an access key for this user and store the key value pair securely.

	c. install aws cli on your local machine and run `aws configure` to setup your account. When prompted, provide the access key from step b, choose region `eu-central-1` and `json` as output format.

	d. Navigate to your AWS ECR Console and get the docker push commands from there.

	In our case, the docker push commands for our private ECR instance are (change version for each image):
	```
	cd node-app
	aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin 010928217051.dkr.ecr.eu-north-1.amazonaws.com
	# remember to change the version each time
	docker build -f Dockerfile -t node-app:1.0 .
	docker tag node-app:1.0 010928217051.dkr.ecr.eu-north-1.amazonaws.com/node-app:1.0
	docker push 010928217051.dkr.ecr.eu-north-1.amazonaws.com/node-app:1.0
	
	```

4. To pull and run a docker image on a remote VPS hosted in the cloud, follow these steps

	a. First, you have to add the IP address of your remote machine and the root user to `config/remote.properties` file.

	b. Navigate to `scripts/` folder and install docker on your remote by executing `./remote-install-docker.sh` (THIS SCRIPT IS FOR FEDORA 40 distribution using dnf package manager).

	c. Add the ECR repository url to your `.env` file in the `AWS_ECR_URL` key.

	d. Then run `./remote-login-to-docker-registry.sh`. This will login to your docker ECR registry so subsequent docker compose and docker run/pull commands are setup correctly.

	e. you will be asked to provide the service user password defined in step b - you will also be queried for the node-app tag you want to use, as this is dynamically set as an ENV variable for docker-compose.

5. To run docker containers with volumes attached, specifically mongodb for persistence, we can use anonymous (named) volumes that are managed by docker, making it easier to deal with file permissions and such.

	To attach a persistent volume on your local file system to a the docker container setup, navigate to `node-app/` directory and run:
	```
	export VERSION_TAG=1.0
        docker compose -f docker-compose-with-volumes.yaml up

	```
	
	Then:
	a. head to localhost:8081 with `admin` and `pass` credentials for mongo-express and add the collection users in the database user-account.

	b. head to localhost:3000 and make updates to the user profile.

	c. stop the docker containers with `docker compose -f docker-compose-with-volumes.yaml down`

	d. the containers were destroyed, now you can run `docker compose -f docker-compose-with-volumes.yaml up` once again and see that the updates from step
	
	b. were persisted.

6. To use the existing nexus repository running on a remote VPS server from demo project 6,  adding a docker-registry to it and pushing images to that registry from localhost, follow these steps

	Get the remote url from demo project 6, in my case https://github.com/hangrybear666/06-devops-bootcamp__nexus_artifact_repo/blob/main/config/remote.properties
	Nexus repository is accessible at `REMOTE_ADDRESS:8081` and the credentials are stored in the `.env` file of your project 6 repo.

	a. Login to the existing nexus repository as an admin user.

	b. Create a new role named `nx-docker` and apply the privilege `nx-repository-view-docker-docker-hosted-*` to it. (NOTE: you might have to create a docker-hosted repo first)

	c. Create a new local user named `docker-creds`

	d. Add `Docker Bearer Token Realm` under Realms.

	e. Create a blob store of type File named `docker-hosted-blob`

	f. Store the relevant credential information in this repository's `.env` file.
	```
	NEXUS_ADMIN_PASSWORD=xxx
	NEXUS_USER_1_ID=docker-creds
	NEXUS_USER_1_PWD=xxx
	```
	g. Create a new Repository of type `docker-hosted`, assign the blob store from step e.  and enable the HTTP flag with port 8082 to allow insecure connections without having to configure HTTPS in nexus.

	h. In your local linux distro with docker installed, edit the  `/etc/docker/daemon.json` file and add:
	```
	{
		"insecure-registries" : [ "REMOTE_ADDRESS:8082" ]
	}
	```
	If the file doesn't exist, create it `sudo vim /etc/docker/daemon.json`
	```
	sudo systemctl daemon-reload
	sudo systemctl restart docker
	docker info
	``` 
	Now docker info should print your nexus repository under insecure registries.

	i. Now login to the nexus docker-hosted repository via: 
	AND DON'T FORGET TO ALLOW PORT 8082 IN YOUR REMOTE VPS FIREWALL
	```
	docker login REMOTE_ADDRESS:8082
	```
	When prompted, provide the credentials defined in your `env` file in step f. namely `NEXUS_USER_1_ID` and `NEXUS_USER_1_PWD`

	j. Now simply build your desired image, tag it and push it to the repository url you logged in to.
	```
	cd node-app
	docker build -f Dockerfile -t node-app:0.1 .
	docker tag node-app:0.1 104.248.37.28:8082/node-app:0.1
	docker push 104.248.37.28:8082/node-app:0.1
	```

	k. Now you can pull the image via a simple docker pull command, or use the nexus API to fetch the hosted versions and fetch the newest via extraction of the downloadUrl via the jq tool, as demonstrated in https://github.com/hangrybear666/06-devops-bootcamp__nexus_artifact_repo 

7. To setup nexus repository within a docker container deployed on a remote host, follow these steps:

	Change directory to the `scripts/` folder and:

	a. First, install docker on your remote VPS, by running `./remote-install-docker-for-nexus.sh` (This is aimed at Debian like distros with the apt-get package manager)

	b. Then run `./remote-run-nexus-docker-img.sh`

	c. Make sure to allow port 8081 forwarding in your VPS firewall settings.

	d. ssh into your remote vps and run the following code to retrieve the default admin password.
	```
	docker ps
	# with the resulting hash run
	docker exec -it HASH_VALUE sh
	~sh: 
	cat /nexus-data/admin.password
	```

	e. With the retrieved password from step d, navigate to REMOTE_ADDRESS:8081, login to nexus and start using the repository. 

	f. Make sure to change the password to the one in our .env file from step 6 `NEXUS_ADMIN_PASSWORD=xxx`

## Usage (Exercises)

0. Setup Environment secrets and configuration

	a. Be sure to have gradle 8 and java 17 installed, I can recommend using sdkman for this https://sdkman.io/install

	b. Create an `.env` file in `exercises/` folder with the following content:
	```
	MYSQL_ROOT_PASSWORD=xxx
	MYSQL_DATABASE=team-member-projects
	MYSQL_USER=mysql-user
	MYSQL_PASSWORD=xxx
	```

	c. If you are executing the local steps on a remote host instead, be sure to open ports 3306 and 8080 and 8085

1. To run a local mysql docker container, mysqlp phpadmin container and a native java spring application locally

	NOTE: If you are running this on a remote host from the get go, you first have to create `target_dir/exercises/` on your remote host via ssh, then recursively copy the `exercises/` folder to your remote via `scp -r exercises root@REMOTE_ADDRESS:~/target_dir/exercises` and you also have to change const HOST = "xxx" to your remote ip address in `exercises/src/main/resources/static/index.html` !

	a. If you want to run the java app on localhost, set const HOST = "localhost" in `exercises/src/main/resources/static/index.html`

	```
	cd exercises
	docker network create mysql-db-gui
	docker run --name mysqldb --env-file .env --network mysql-db-gui -p 3306:3306 -d mysql:9.0.1
	
	# to connect as a mysql client to execute queries from another docker container run
	docker run -it --network mysql-db-gui --rm mysql:9.0.1 mysql -hmysqldb -umysql-user -p

	# to start phpmyadmin on port 8085 linked to the docker container db
	docker run --name phpmyadmin --network mysql-db-gui -d --link mysqldb:db -p 8085:80 phpmyadmin:5.2.1-apache

	# build and run .jar file running tomcat on port 8080 running as a service in the background with nohup &
	gradle clean build
	cd build/libs
	export DB_USER=mysql-user DB_PWD=sdfpokfepok2012d DB_SERVER=localhost DB_NAME=team-member-projects
	nohup java -jar docker-exercises-project-1.0-SNAPSHOT.jar &
	```
	
	b. Then you can connect to your phpmyadmin instance by accessing `localhost:8085` and logging in via `MYSQL_USER` and `MYSQL_PASSWORD` 
	c. You can connect to your java application by accessing `localhost:8080`


2. To run a mysql db and phpmyadmin with docker compose 

	```
	cd exercises
	docker compose -f docker-compose-mysql.yaml up
	```

3. To build and push the Java application as a docker image to nexus repository hosted in a remote VPS

	```
	docker build -f Dockerfile -t java-app:1.0 .
	# docker run --name java-app -e DB_PWD=sdfpokfepok2012d --network mysql-db-gui -p 8080:8080 java-app:1.4
	
	docker login REMOTE_ADDRESS_2:8082
	Username: NEXUS_USER_1_ID
	Password: NEXUS_USER_1_PWD

	docker tag java-app:1.0 104.248.37.28:8082/java-app:1.0
        docker push 104.248.37.28:8082/java-app:1.0

	```

	NOTE: Check in Demo Projects step 6 how to setup the new nexus docker container properly.
