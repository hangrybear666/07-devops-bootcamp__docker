# Using Docker to Deploy artifacts on remote VPS host machines.

Collection of Dockerfiles, docker-compose files and shell scripts for automating web app deployment on remote VPS hosts.

## Setup

1. Pull SCM

	Pull the repository locally by running 
	```
  	git clone https://github.com/hangrybear666/07-devops-bootcamp__docker.git
	```

2. Create Remote Linux VPS and configure

	Generate local ssh key and add to remote VPS's `authorized_keys` file.

3. Install additional dependencies on remote

	Some Linux distros ship without the `netstat` command we use. In that case run `apt install net-tools` or `dnf install net-tools` on fedora et cetera. Do the same with the `jq` package for parsing .json files for step 10 of the Exercises.

4. Create environment file in node-app/ folder and add secrets
	Add an `.env` file in your repository's node-app directory and add the following key value-pairs:
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

5. Install docker locally.

	Make sure to install docker and docker-compose (typically built-in) for local development.


## Usage (Demo Projects)

1. To run a node-js app, mongodb and mongo-express together in local development.

	To run these 3 images in the same network, simply run `docker-compose up` in the `node_app/` folder.
	Mongodb is being initialized with a seed script to create a database and collection via `seed-mongodb.js` automatically, so interaction with mongo-express is not required.


5. Add your Remote Hostname and IP to config/remote.properties

	First, you have to add the IP address of your remote machine and the root user to `config/remote.properties` file.


## Usage (Exercises)
