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

4. Create environment file and add secrets
	Add an `.env` file in your repository's root directory and add the following key value-pairs:
	```
	ASD=
	```

5. Install docker locally.

	Make sure to install docker and docker-compose (typically built-in) for local development.


## Usage (Demo Projects)

1. Add your Remote Hostname and IP to config/remote.properties

	First, you have to add the IP address of your remote machine and the root user to `config/remote.properties` file.


## Usage (Exercises)
