FROM gethue/hue:latest
LABEL maintainer="rexrliu@gmail.com"

################################################################################
# update and install basic tools
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -yq curl software-properties-common vim openssh-server wget

################################################################################
# set environment variables
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV HADOOP_HEAPSIZE=8192
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_INSTALL=$HADOOP_HOME
ENV HADOOP_MAPRED_HOME=$HADOOP_INSTALL
ENV HADOOP_COMMON_HOME=$HADOOP_INSTALL
ENV HADOOP_HDFS_HOME=$HADOOP_INSTALL
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV YARN_HOME=$HADOOP_INSTALL
ENV HIVE_HOME=/usr/local/hive
ENV SPARK_HOME=/usr/local/spark
ENV HUE_HOME=/usr/share/hue

ENV PATH=$HADOOP_HOME/bin:$HADOOP_INSTALL/sbin:$HIVE_HOME/bin:$SPARK_HOME/bin:$PATH
ENV CLASSPATH=$HADOOP_HOME/lib/*:HIVE_HOME/lib/*:.

################################################################################
# add the above env for all users
RUN echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment
RUN echo "HADOOP_HEAPSIZE=HADOOP_HEAPSIZE" >> /etc/environment
RUN echo "HADOOP_HOME=$HADOOP_HOME" >> /etc/environment
RUN echo "HADOOP_INSTALL=$HADOOP_INSTALL" >> /etc/environment
RUN echo "HADOOP_MAPRED_HOME=$HADOOP_MAPRED_HOME" >> /etc/environment
RUN echo "HADOOP_COMMON_HOME=$HADOOP_COMMON_HOME" >> /etc/environment
RUN echo "HADOOP_HDFS_HOME=$HADOOP_HDFS_HOME" >> /etc/environment
RUN echo "HADOOP_CONF_DIR=$HADOOP_CONF_DIR" >> /etc/environment
RUN echo "YARN_HOME=$YARN_HOME" >> /etc/environment
RUN echo "HIVE_HOME=$HIVE_HOME" >> /etc/environment
RUN echo "SPARK_HOME=$SPARK_HOME" >> /etc/environment
RUN echo "HUE_HOME=$HUE_HOME" >> /etc/environment
RUN echo "PATH=$PATH" >> /etc/environment
RUN echo "CLASSPATH=$CLASSPATH" >> /etc/environment

################################################################################
# add hue configuration file
ADD x-hui.ini /usr/share/hue/desktop/conf

################################################################################
# install hadoop
RUN mkdir $HADOOP_HOME
RUN curl -s http://archive.apache.org/dist/hadoop/core/hadoop-2.7.2/hadoop-2.7.2.tar.gz | tar -xz -C $HADOOP_HOME --strip-components 1

# replace configuration templates
RUN rm -f $HADOOP_CONF_DIR/core-site.xml
RUN rm -f $HADOOP_CONF_DIR/hadoop-env.sh
RUN rm -f $HADOOP_CONF_DIR/hdfs-site.xml
RUN rm -f $HADOOP_CONF_DIR/mapred-site.xml
RUN rm -f $HADOOP_CONF_DIR/yarn-site.xml

ADD core-site.xml $HADOOP_CONF_DIR/core-site.xml
ADD hadoop-env.sh $HADOOP_CONF_DIR/hadoop-env.sh
ADD hdfs-site.xml $HADOOP_CONF_DIR/hdfs-site.xml
ADD mapred-site.xml $HADOOP_CONF_DIR/mapred-site.xml
ADD yarn-site.xml $HADOOP_CONF_DIR/yarn-site.xml

################################################################################
# setup ssh
RUN mkdir /root/.ssh
RUN cat /dev/zero | ssh-keygen -q -N "" > /dev/null && cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys

################################################################################
# install hive
RUN mkdir $HIVE_HOME
RUN curl -s https://archive.apache.org/dist/hive/hive-2.3.4/apache-hive-2.3.4-bin.tar.gz | tar -xz -C $HIVE_HOME --strip-components 1
ADD hive-site.xml $HIVE_HOME/conf/hive-site.xml

################################################################################
# format HFS
RUN $HADOOP_HOME/bin/hdfs namenode -format -nonInteractive

################################################################################
# install MySQL
ENV MYSQL_PWD Pwd123
RUN echo "mysql-server mysql-server/root_password password $MYSQL_PWD" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password $MYSQL_PWD" | debconf-set-selections
RUN apt-get -y install mysql-server

RUN chown -R mysql:mysql /var/lib/mysql
RUN usermod -d /var/lib/mysql/ mysql

RUN wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.15.tar.gz
RUN tar -xzf mysql-connector-java-8.0.15.tar.gz
RUN cp mysql-connector-java-8.0.15/mysql-connector-java-8.0.15.jar $HIVE_HOME/lib
RUN rm -rf mysql-connector-java-8.0.15*

################################################################################
# install spark
RUN curl -s http://www.gtlib.gatech.edu/pub/apache/spark/spark-2.3.3/spark-2.3.3-bin-hadoop2.7.tgz | tar -xz -C /usr/local
RUN mv /usr/local/spark-2.3.3-bin-hadoop2.7 $SPARK_HOME

################################################################################
# expose port
# Hadoop Resource Manager
EXPOSE 8088

# Hadoop NameNode
EXPOSE 50070

# Hadoop DataNode
EXPOSE 50075

# Hive WebUI
EXPOSE 10002

# Hive Master
EXPOSE 10000

# Hue WebUI
EXPOSE 8888

# SSH
EXPOSE 22

################################################################################
# add users and groups
RUN groupadd hdfs && groupadd hadoop && groupadd hive && groupadd mapred && groupadd spark
RUN useradd -g hadoop hdpu && echo "hdpu:hdpu123" | chpasswd && adduser hdpu sudo

RUN usermod -a -G hdfs hdpu
RUN usermod -a -G hadoop hdpu
RUN usermod -a -G hive hdpu
RUN usermod -a -G mapred hdpu
RUN usermod -a -G spark hdpu
RUN usermod -a -G hue hdpu

################################################################################
# create startup script and set ENTRYPOINT
ADD start.sh /usr/local/sbin
ENTRYPOINT /bin/bash /usr/local/sbin/start.sh
