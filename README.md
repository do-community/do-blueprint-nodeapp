## DigitalOcean Blueprint - Node.js Web App

Welcome to the Node.js Web App Blueprint repository.  This repository can be used to quickly set up a 2 node infrastructure with NGINX, Node.js, and MongoDB configured and ready to start developing and deploying in a secured environment that is ready to scale.

This process should take between 5 and 10 minutes. 

After cloning the project and executing the Terraform and Ansible steps described below, you will have a layered Web, App and Data infrastructure.  Web and app layers are deployed on a single compute server, and the database is on it's own server.  Data will be stored on hardware redundant block storage, and firewalls will be configured in front of each server to filter out undesirable traffic.  The final configuration will look as follows:

### Architecture of Node.js Web App Blueprint - version 1
![](https://blueprint-nodejs.nyc3.digitaloceanspaces.com/blueprint-v2.png)


- **1** 1GB Droplet for NGINX and Node.js
	- Specs: 1 VCPU, 1GB memory, and 25 GB SSD
	- Datacenter: SFO2 
	- OS: Ubuntu 16.04
	- Software: Node.js v6.13.0, NGINX v 1.10.3

- **1** 1GB Droplet for MongoDB
	- Specs: 1 VCPU, 1GB memory, and 25 GB SSD
	- Datacenter: SFO2 
	- Private Networking enabled
	- Software: Ubuntu 16.04, MongoDB v3.6

- **1** 100GB block storage drive, which provides hardware redudancy and the ability to resize the volume, also located in the SFO2 datacenter.  This 100 GB volume will be mounted to the MongoDB server at /var/mnt/dbvolume, and mongoDB will be configured to store data on this volume.

- **4** Cloud Firewalls, to filter out all traffic except HTTP/HTTPS, SSH, Node App (configured for port 8080), and MongoDB.

Using the given Droplet sizes, and 100 GB of block stroage, **this infrastructure will cost $20 a month** to run. 


The software versions installed include:
- Nginx version 1.10.3
- Node.js version 6.13.0
- MongoDB version 3.6

In addition a boilerplace node web app will be installed, using this [Node.js starter app boilerplate](https://github.com/sahat/hackathon-starter).


## Quickstart

Here are the steps to get up and running.  

### Requirements

The software required to run DigitalOcean Blueprints are provided within a Docker image.  You will need to install Docker locally to run these playbooks.  You can find up-to-date instructions on how to download and install Docker on your computer [on the Docker website](https://www.docker.com/community-edition#/download).

If you'd prefer not to install Docker locally, you can create a dedicated control Droplet using the [DigitalOcean Docker One-click application](https://www.digitalocean.com/products/one-click-apps/docker/) instead.  You will also need [git](https://git-scm.com/downloads) available if it's not already installed.

### Clone the Repo

To get started, clone this repository to your Docker server into a writeable directory:

```
cd ~
git clone https://github.com/do-community/do-blueprint-nodeapp
```

### Add a Bash Alias for the Infrastructure Tools Docker Container

Open your shell configuration file using your preferred text editor:

```
nano ~/.bashrc
```

Inside, at the bottom, add a function and definition for `complete` to simplify usage of the Docker image:

```
. . .
function bp() {
    docker run -it --rm \
    -v "${PWD}":"/blueprint" \
    -v "${HOME}/.terraform.d":"/root/.terraform.d" \
    -v "${HOME}/.ssh":"/root/.ssh" \
    -v "${HOME}/.config":"/root/.config" \
    -e ANSIBLE_TF_DIR='./terraform' \
    -e HOST_HOSTNAME="${HOSTNAME}" \
    docommunity/bp "$@"
}

complete -W "terraform doctl ./terraform.py ansible ansible-connection ansible-doc ansible-inventory ansible-pull ansible-config ansible-console ansible-galaxy ansible-playbook ansible-vault" "bp"
```

Save and close the file when you are finished.  Source the file to read in the new function to your current session:

```
source ~/.bashrc
```

### Run the `setup.yml` Local Playbook

Next, enter the repository directory and run the `setup.yml` playbook.  This will configure the local repository and credentials.

*Note*: The initial run of this playbook may show some warnings since the Ansible dynamic inventory script cannot yet find a valid state file from Terraform.  This is expected and the warnings will not be present once a Terraform state file is created.

```
bp ansible-playbook setup.yml
```

Enter your DigitalOcean read/write API key if prompted (you can generate a read/write API key by visiting the [API section of the DigitalOcean Control Panel](https://cloud.digitalocean.com/settings/api/tokens) and clicking "Generate New Token").  Confirm the operation to create a dedicated SSH key pair by typing "yes" at when prompted.  As part of this configuration, a dedicated SSH key pair will be generated for managing Blueprints infrastructure and added to your DigitalOcean account.

The playbook will:

* Check the `doctl` configuration to try to find an existing DigitalOcean API key
* Prompt you to enter an API key if it could not find one in the `doctl` configuration
* Check if a dedicated `~/.ssh/blueprint-id_rsa` SSH key pair is already available locally.
* Generate the `~/.ssh/blueprint-id_rsa` key pair if required and add it to your DigitalOcean account.
* Install the Terraform Ansible provider and the associated Ansible dynamic inventory script that allows Ansible to read from the Terraform state file
* Generate a `terraform/terraform.tfvars` file with your DigitalOcean API key and SSH key defined
* Initialize the `terraform` directory so that it's ready to use.
* Install the Ansible roles needed to run the main playbook.

### Create the Infrastructure

Move into the `terraform` directory.  Adjust the `terraform.tfvars` and `main.tf` file if necessary (to adjust the number or size of your servers for instance).  When you are ready, create your infrastructure with `terraform apply`:

```
cd terraform
bp terraform apply
```

Type `yes` to confirm the operation.

### Apply the Configuration

Move back to the main repository directory.  Use the `ansible -m ping` command to check whether the hosts are accessible yet:

```
cd ..
bp ansible -m ping all
```

This command will return failures if the servers are not yet accepting SSH connections or if the userdata script that installs Python has not yet completed.  Run the command again until these failures disappear from all hosts.

Once the hosts are pinged successfully, apply the configuration with the `ansible-playbook` command. The infrastructure will be configured primarily using the values of the variables set in the `group_vars` directory and in the role defaults:

```
bp ansible-playbook site.yml
```

### Accessing the Hosts

To display the IP addresses for your infrastructure, you can run the `./terraform.py` script manually by typing:

```
bp ./terraform.py
```

Among other information, you should be able to see the IP addresses of each of your servers:

```
  . . .
  "_meta": {
   	"hostvars": {
      "nodejs-1": {
        "ansible_host": "159.65.102.14"
      }, 
      "mongodb-1": {
        "ansible_host": "159.65.110.150"
      }
    }    
  }
}
```


### Testing the Deployment

Once the infrastructure is configured, you can SSH into the node.js server to check that NGINX and Node.js are running.  SSH into the NGINX and Node host from the computer with your Blueprint repository (this machine will have the correct SSH credentials).

1. To check if nginx is running, in the terminal type ```'ps waux | grep nginx'``` and you should see the ngninx process running

2. To check if node.js is installed, ssh to your new server and type ```'node -v'``` and you should see the version of node that has been installed:

```
v6.13.1
```

#### Connect to the mongoDB server
You can SSH into the mongoDB server to check that mongoDB is running.  SSH into the mongoDB host from the computer with your Blueprint repository.


To check if the mongoDB port is up, in the terminal type ```'nc -v localhost 27017'``` and you should be able to connect to mongodb on port 27017

	
To check if the block storage volume is available on the database server, in the terminal type ```'lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL'```

### Deprovisioning the Infrastructure

To destroy all of the servers in this Blueprint, move into the `terraform` directory again and use the `destroy` action:

```
cd terraform
bp terraform destroy
```

You will be prompted to confirm the action.  While you can easiliy spin up the infrastructure again using the Terraform and Ansible steps, keep in mind that any data you added will be lost on deletion.

## Ansible Roles

This project uses the following roles to configure NGINX, Node.js, and MongoDB:

* [NGINX ansible role](https://github.com/jdauphant/ansible-role-nginx)
* [Node.JS ansible role](https://github.com/geerlingguy/ansible-role-nodejs)
* [MongoDB ansible role](https://github.com/UnderGreen/ansible-role-mongodb)

You can read the README files associated with each role to understand how to adjust the configuration.

## Customizing this Blueprint

You can customize this Blueprint in a number of ways depending on your needs.

### Modifying Infrastructure Scale

**Note:** Adjusting the scale will affect the cost of your deployment.

To adjust the scale of your infrastructure, open the `terraform/main.tf`file in a text editor:

```
nano terraform/main.tf
```

You can change the number of node.js members by adjusting the `count` parameter in the `digitalocean_droplet` definition for the `nodejs` resources:

```
. . .
resource "digitalocean_droplet" "nodejs" {
  count     = "1"
. . .
```


To vertically scale either the node.js servers or the mongoDB server, you can adjust the `size` parameter associated with the instances.  Use `bp doctl compute size list` to get a list of available Droplet sizes.

### Adjusting the Software Configuration

To adjust the way node, nginx, and mongoDB is deployed you need to modify the parameters that the Ansible playbook uses to configure each service.  The Ansible configuration for these components is primarily defined within the top-level `group_vars` directory and in the role defaults files (found in `roles/<role_name>/defaults/main.yml` after running the `setup.yml` playbook).

To understand what each variable means and how they work, read the variable descriptions within the README files associated with the individual roles.

Some of the items you may want to change:
* To use a clone a different boilerplate app, update the variables `git_repo_name` and `git_repo_url` in `roles/runstarterapp/defaults/main.yml`
* To change the directory location of your node app, update the variable `project_folder_name` in `roles/runstarterapp/defaults/main.yml`
* To change the node.js version, update the variable `nodejs_version` in `roles/nodejs/defaults/main.yml`


### Backlog of features
* Configure nginx to proxy port 80 traffic to the node app running on 8080
* Format the block storage volume as XFS
