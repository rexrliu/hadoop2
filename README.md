# hadoop2
This Dockerfile allows you to install Hadoop2, Hive2, Spark2, and Hue in one container.


Build Image
===========

docker build -t hadoop2 .

Run container
=============
docker run -it -p 8088:8088 -p 50070:50070 -p 50075:50075 -p 10000:10000 -p 10002:10002 -p 8888:8888 hadoop2 /usr/local/sbin/start.sh
