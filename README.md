# Docker Auto Scale on Debian
This is simple sh scripts to scale docker container without the need of Kubernetes or Openshift.
Before running it all the container instance must be created before the script start.
The script will start you instance according to your running container cpu and memory usage. 
If the average is upper the max threshold it will start the next new instance. If the cpu and memory average are lower than the minimum threshold it will stop a container.

## Run the script 
### Edit file docker-autoscale.env
Replace with your requirements

### Start one
Run
```
./docker-autoscale.sh
```

### Multiple application
Create as many env file as you have application to scale
```
./docker-autoscale-multiple.sh
```


## Systemctl service
### Install
Run
```
./install-autoscale.sh
```

### Configure env in etc/docker-autoscale
Creates as many env file as you need. One per application.
### Uninstall
```
./uninstall-autoscale.sh
```
