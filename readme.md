# Docker for PSQ Streaming Serve

# build

## local

```
docker build -t psq-streaming-server \
--build-arg PSQ_API_HOST=psqapi.neostore.net \
--add-host 127.0.0.1:192.168.0.1  . 

```

## prod

```
docker build -t psq-streaming-server \
--build-arg APP_ENV=production \
--build-arg PSQ_API_HOST=psqapi.neostore.net \
--build-arg SERVER_NAME=psq.streaming.com .
```


* run container 

```
docker run --name psq-streaming-server1 \
-p 8080:80 -p 8081:443 -p 1935:1935 -it \
--net=docker-bridge \
-d psq-streaming-server
```

# Connect

````
docker exec -it psq-streaming-server1 /bin/bash
````

````
service --status-all
````
