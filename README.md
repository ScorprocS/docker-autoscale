# Docker Auto Scale on Debian

Before running it all the container instance must be created before the script start


## Run the script 
### Edit file docker-autoscale.env
Replace with your requirements

### Start one
Run
'''
./docker-autoscale.sh
'''


## Systemctl service
### Install
Run
'''
./install-autoscale.sh
'''

### Configure env in etc/docker-autoscale
Creates as many env file as you need. One per application.
### Uninstall
'''
./uninstall-autoscale.sh
'''
