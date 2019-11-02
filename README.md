# hadoop2
Build docker image that includes Hadoop2, Hive2, Spark2, Tez0.9, and Hue4


Build Image
===========
docker build -t hadoop2 .

Run container
=============
docker run --rm -p 8088:8088 -p 50070:50070 -p 50075:50075 -p 10000:10000 -p 10002:10002 -p 8888:8888 -p 8022:22 hadoop2 &

Login to the server
=============
ssh -p 8022 hdpu@localhost (password: hdpu123, this is a sudo user)

Features
=============
* Both file and table browsers are enabled on Hue
* Spark access to Hive tables is enable
* Multiple Hive execution engines: MR (mapreduce), Spark, or Tez
* The default Derby database for Hive metastore and SQLite for Hue are replaced
with MySQL (more robust and similar to real production environments)
* Common aliases of Hadoop commands are provided
