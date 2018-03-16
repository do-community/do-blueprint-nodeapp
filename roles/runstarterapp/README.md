# Ansible Role: Run blueprint app

An ansible role to clone a node app and run it


## Requirements

* git
* blueprint app

## Role Variables

```
    git_repo_name: gitreponame
```
* Type: string
* Default: (none)
* Description: The name of the git repo

```
    git_repo_url: gitrepoURL
```
* Type: string
* Default: (none)
* Description: The URL of the git repo

```
    git_repo_ssh_private_key: false
```
* Type: boolean
* Default: false
* Description: Boolean whether an ssh private key is needed 

```
    git_repo_ssh_public_key: false
```
* Type: boolean
* Default: false
* Description: Boolean whether an ssh public key is needed 

```
    git_repo_command: false
```
* Type: boolean
* Default: false
* Description: Boolean whether to issue a git repo command


```
    MONGODB_URI: databaseURI
```
* Type: string
* Default: (none)
* Description: The name of the git repo

## Dependencies

* None

## Example Playbook

	- name: Clone hackathon-starter github repo
	  hosts: nodejs
	  vars:
		git_repo_name: sahat/hackathon-starter
		git_repo_url: https://github.com/sahat/hackathon-starter.git
		git_repo_ssh_private_key: false
	 	git_repo_ssh_public_key: false
		project_folder_name: starter

    - name: Run the Node.js Blueprint app 
      hosts: nodejs
	  vars:
        mongodb_env_variable: MONGODB_URI
        mongodd_env_value: mongodb://159.65.108.205:27017/test


    roles:
    - role: runstarterapp


## License

* MIT

## Author Information

* DigitalOcean Community
