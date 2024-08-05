# Using Docker to Deploy artifacts on remote VPS host machines

Collection of Dockerfiles, docker-compose files and shell scripts for automating web app deployment on remote VPS hosts.

The main packages are:
- A local mongodb, mongo-express and node-js development stack
- 

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

5. Install docker locally.

	Make sure to install docker and docker-compose (typically built-in) for local development. See https://docs.docker.com/engine/install/

6. Install docker on remote.

	Ensure docker is installed on your remote VPS intended to run the node-app with mongo-db. See https://docs.docker.com/engine/install/

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
	a. head to localhost:8081 with `admin` and `pass` credentials for mongo-express and add the collection users in the database user-account
	b. head to localhost:3000 and make updates to the user profile.
	c. stop the docker containers with `docker compose -f docker-compose-with-volumes.yaml down` 
	

## Usage (Exercises)
