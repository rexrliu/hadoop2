#!/bin/bash

# start hadoop
service ssh start
ssh-keyscan localhost > /root/.ssh/known_hosts
# ssh-keyscan ::1 >> /root/.ssh/known_hosts && \
ssh-keyscan 0.0.0.0 >> /root/.ssh/known_hosts
#$HADOOP_HOME/sbin/start-yarn.sh
#$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-all.sh

$HADOOP_HOME/bin/hdfs dfs -mkdir /tmp
$HADOOP_HOME/bin/hdfs dfs -chmod 777 /tmp
$HADOOP_HOME/bin/hadoop fs -mkdir -p /user/hive/warehouse
$HADOOP_HOME/bin/hadoop fs -chmod g+w /user/hive/warehouse

# start hive
cd $HIVE_HOME && bin/hiveserver2 > /dev/null 2>&1 &

# start mysql
chown -R mysql:mysql /var/lib/mysql
usermod -d /var/lib/mysql/ mysql
service mysql start

echo """
  CREATE USER 'hue'@'localhost' IDENTIFIED BY 'hue';
  GRANT ALL PRIVILEGES on *.* to 'hue'@'localhost' WITH GRANT OPTION;
  GRANT ALL on hue.* to 'hue'@'localhost' IDENTIFIED BY 'hue';
  FLUSH PRIVILEGES;
  CREATE DATABASE hue;
""" | mysql --user=root --password=$MYSQL_PWD

# start hue
$HUE_HOME/build/env/bin/hue syncdb --noinput
$HUE_HOME/build/env/bin/hue migrate
$HUE_HOME/build/env/bin/supervisor > /dev/null 2>&1 &

cd /
/bin/bash
