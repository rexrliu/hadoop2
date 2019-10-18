FROM ubuntu:16.04
LABEL maintainer="rexrliu@gmail.com"

WORKDIR /
################################################################################
# update and install basic tools
RUN apt-get update && apt-get upgrade -y && apt-get install --fix-missing -yq \
  git \
  ant \
  gcc \
  g++ \
  libkrb5-dev \
  libmysqlclient-dev \
  libssl-dev \
  libsasl2-dev \
  libsasl2-modules-gssapi-mit \
  libsqlite3-dev \
  libtidy-0.99-0 \
  libxml2-dev \
  libxslt-dev \
  libffi-dev \
  make \
  maven \
  libldap2-dev \
  python-dev \
  python-setuptools \
  libgmp3-dev \
  libz-dev \
  curl \
  software-properties-common \
  vim \
  openssh-server \
  wget \
  openjdk-8-jdk \
  sudo

################################################################################
# install MySQL
ENV MYSQL_PWD=Pwd123
RUN echo "mysql-server mysql-server/root_password password $MYSQL_PWD" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password $MYSQL_PWD" | debconf-set-selections
RUN apt-get install -y mysql-server

RUN chown -R mysql:mysql /var/lib/mysql
RUN usermod -d /var/lib/mysql/ mysql

################################################################################
# setup ssh
RUN mkdir /root/.ssh
RUN cat /dev/zero | ssh-keygen -q -N "" > /dev/null && cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys

################################################################################
# set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
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
ENV HUE_HOME=/usr/local/hue
ENV TEZ_HOME=/usr/local/tez
ENV IMPALA_HOME=/usr/local/impala

ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_INSTALL/sbin:$HIVE_HOME/bin:$SPARK_HOME/bin:$PATH
ENV CLASSPATH=$HADOOP_HOME/lib/*:HIVE_HOME/lib/*:.
ENV LD_LIBRARY_PATH=$HADOOP_HOME/lib/native

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
RUN echo "TEZ_HOME=$TEZ_HOME" >> /etc/environment
RUN echo "IMPALA_HOME=$IMPALA_HOME" >> /etc/environment
RUN echo "PATH=$PATH" >> /etc/environment
RUN echo "CLASSPATH=$CLASSPATH" >> /etc/environment
RUN echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> /etc/environment

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

# format HFS
RUN $HADOOP_HOME/bin/hdfs namenode -format -nonInteractive

################################################################################
# install hive
RUN mkdir $HIVE_HOME
RUN curl -s https://archive.apache.org/dist/hive/hive-2.3.4/apache-hive-2.3.4-bin.tar.gz | tar -xz -C $HIVE_HOME --strip-components 1
ADD hive-site.xml $HIVE_HOME/conf/hive-site.xml
# ADD hive-env.sh $HIVE_HOME/conf/hive-env.sh

################################################################################
# install impala
RUN wget -O /etc/apt/sources.list.d/cloudera.list http://archive.cloudera.com/impala/ubuntu/precise/amd64/impala/cloudera.list
RUN apt-get update && apt-get install --allow-unauthenticated -y impala-server impala impala-state-store impala-catalog
ADD impala /etc/default

################################################################################
# install spark
RUN curl -s https://archive.apache.org/dist/spark/spark-2.3.3/spark-2.3.3-bin-hadoop2.7.tgz | tar -xz -C /usr/local
RUN mv /usr/local/spark-2.3.3-bin-hadoop2.7 $SPARK_HOME

# config spark to read hive tables
RUN ln -s $HADOOP_HOME/etc/hadoop/core-site.xml $SPARK_HOME/conf/
RUN ln -s $HADOOP_HOME/etc/hadoop/hdfs-site.xml $SPARK_HOME/conf/
RUN ln -s $HIVE_HOME/conf/hive-site.xml $SPARK_HOME/conf/

# config hive on spark
RUN ln -s $SPARK_HOME/jars/scala-library*.jar $HIVE_HOME/lib/
RUN ln -s $SPARK_HOME/jars/spark-core*.jar $HIVE_HOME/lib/
RUN ln -s $SPARK_HOME/jars/spark-network-common*.jar $HIVE_HOME/lib/
RUN ln -s $SPARK_HOME/jars/spark-unsafe*.jar $HIVE_HOME/lib/

################################################################################
# install tez
RUN mkdir $TEZ_HOME
RUN curl -s https://www.apache.org/dist/tez/0.9.1/apache-tez-0.9.1-bin.tar.gz | tar -zx -C $TEZ_HOME --strip-components 1
# RUN cp $TEZ_HOME/*.jar $HIVE_HOME/lib/
ADD tez-site.xml $TEZ_HOME/conf/tez-site.xml

################################################################################
# install hue
RUN mkdir $HUE_HOME
RUN curl -L https://www.dropbox.com/s/0rhrlnjmyw6bnfc/hue-4.2.0.tgz?dl=0 | tar -zx -C $HUE_HOME --strip-components 1
WORKDIR $HUE_HOME
RUN make apps

RUN rm -f $HUE_HOME/desktop/conf/hue.ini
ADD hue.ini $HUE_HOME/desktop/conf

################################################################################
# add mysql jdbc driver
RUN wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.15.tar.gz
RUN tar -xzf mysql-connector-java-8.0.15.tar.gz
RUN cp mysql-connector-java-8.0.15/mysql-connector-java-8.0.15.jar $HIVE_HOME/lib
RUN cp mysql-connector-java-8.0.15/mysql-connector-java-8.0.15.jar $SPARK_HOME/jars/
RUN rm -rf mysql-connector-java-8.0.15 mysql-connector-java-8.0.15.tar.gz

################################################################################
# add users and groups
RUN groupadd hadoop && groupadd mapred && groupadd spark && groupadd tez

RUN useradd -g hadoop hdpu && echo "hdpu:hdpu123" | chpasswd && adduser hdpu sudo
RUN useradd -g hdfs hdfs
RUN usermod -s /bin/bash hdpu

RUN usermod -a -G hdfs hdpu
RUN usermod -a -G hadoop hdpu
RUN usermod -a -G hive hdpu
RUN usermod -a -G mapred hdpu
RUN usermod -a -G spark hdpu
RUN usermod -a -G tez hdpu
RUN usermod -a -G impala hdpu
RUN usermod -a -G hadoop impala
RUN usermod -a -G hdfs impala


RUN mkdir /home/hdpu
RUN chown -R hdpu:hadoop /home/hdpu
RUN echo "source /home/hdpu/.bashrc" > /home/hdpu/.profile
ADD bashrc /home/hdpu/.bashrc
RUN chown hdpu:hadoop /home/hdpu/.bashrc /home/hdpu/.profile

RUN mkdir -p /var/run/hdfs-sockets && chown -R hdfs:hdfs /var/run/hdfs-sockets
RUN mkdir -p /data/log/impala && chown -R impala:impala /data/log/impala

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

# Spark WebUI
EXPOSE 7180

# Impala
EXPOSE 21050

# SSH
EXPOSE 22

################################################################################
# create startup script and set ENTRYPOINT
WORKDIR /
ADD start.sh /usr/local/sbin
ENTRYPOINT /bin/bash /usr/local/sbin/start.sh
