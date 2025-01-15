# Docker Auto Scale on Debian
This is simple sh scripts to scale docker container without the need of Kubernetes or Openshift.
Before running it all the container instance must be created before the script start.
The script will start you instance according to your running container cpu and memory usage. 
If the average is upper the max threshold it will start the next new instance. If the cpu and memory average are lower than the minimum threshold it will stop a container.

## Setup max cpu and max memory usage to your container
With docker run
```
docker run ... --cpus=1 --memory=2g 
         
```
With docker-compose
```
services:
  deploy:
      resources:
        limits:
          cpus: '1'           # Adjust based on server capacity
          memory: '2000M'         # Adjust based on server capacity
```

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

### Configure env in /etc/docker-autoscale
Creates as many env file as you need. One per application.
### Uninstall
```
./uninstall-autoscale.sh
```
