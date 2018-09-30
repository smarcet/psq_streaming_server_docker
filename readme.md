# Docker for PSQ Streaming Serve

# install docker

````
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable edge"
apt-cache policy docker-ce
sudo apt-get install -y docker-ce
sudo systemctl status docker
sudo usermod -aG docker ${USER}
su ${USER}
````

# build

## local

```
docker build -t psq-streaming-server \
--build-arg PSQ_API_HOST=psqapi.neostore.net \
--add-host 127.0.0.1:192.168.0.1  . 

```

## prod

### create ssl certs
````
docker run -it --rm \
-v letsencrypt-etc:/etc/letsencrypt \
-v letsencrypt-lib:/var/lib/letsencrypt \
-v /home/smarcet/webroot:/data/letsencrypt \
-v letsencrypt-log:/var/log/letsencrypt \
certbot/certbot \
certonly --webroot \
--register-unsafely-without-email --agree-tos \
--webroot-path=/data/letsencrypt \
--staging \
-d psqstream.neostore.net
````
````
docker run -it --rm \
-v letsencrypt-etc:/etc/letsencrypt \
-v letsencrypt-lib:/var/lib/letsencrypt \
-v /home/smarcet/webroot:/data/letsencrypt \
-v letsencrypt-log:/var/log/letsencrypt \
certbot/certbot \
certonly --webroot \
--email smarcet@gmail.com --agree-tos --no-eff-email \
--webroot-path=/data/letsencrypt \
-d psqstream.neostore.net
````

```
docker build -t psq-streaming-server \
--build-arg APP_ENV=production \
--build-arg PSQ_API_HOST=psqapi.neostore.net \
--build-arg SERVER_NAME=psqstream.neostore.net .	
```


* run container 

```
docker network create -d bridge --subnet 192.168.0.0/24 --gateway 192.168.0.1 docker-bridge

docker run --name psq-streaming-server1 \
-p 80:80 -p 443:443 -p 1935:1935 \
-v letsencrypt-etc:/etc/letsencrypt \
-v /home/smarcet/webroot:/data/letsencrypt \
--net=docker-bridge \
-m 8GB --oom-kill-disable \
--restart=always \
-d psq-streaming-server
```

# Connect

````
docker exec -it psq-streaming-server1 /bin/bash
````

````
service --status-all
````
	
	




