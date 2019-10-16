# hadoop2
This Dockerfile is for the installation of Hadoop2, Hive2, Spark2, and Hue4 in one container.


Build Image
===========
docker build -t hadoop2 .

Run container
=============
docker run --rm -p 8088:8088 -p 50070:50070 -p 50075:50075 -p 10000:10000 -p 10002:10002 -p 8888:8888 -p 8022:22 -p 8080:8080 -p 8188:8188 hadoop2 &

Login to the server
=============
ssh -p 8022 hdpu@localhost (password: hdpu123, this is a sudo user)

Features
=============
Hue file browser and table browser are enabled
Spark access to Hive tables is configured
