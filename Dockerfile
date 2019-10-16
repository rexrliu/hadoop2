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
  sudo \
  openjdk-8-jdk \
  unzip

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
ENV TEZ_HOME=/usr/local/tez
ENV CATALINA_HOME=/usr/local/tomcat
ENV SPARK_HOME=/usr/local/spark
ENV HUE_HOME=/usr/local/hue
ENV HIVE_CONF_DIR=$HIVE_HOME/conf/

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
ADD yarn-env.sh $HADOOP_CONF_DIR/yarn-env.sh

# format HFS
RUN $HADOOP_HOME/bin/hdfs namenode -format -nonInteractive

################################################################################
# install hive
RUN mkdir $HIVE_HOME
RUN curl -s https://archive.apache.org/dist/hive/hive-2.3.4/apache-hive-2.3.4-bin.tar.gz | tar -xz -C $HIVE_HOME --strip-components 1
ADD hive-site.xml $HIVE_HOME/conf/hive-site.xml

################################################################################
# install spark
RUN curl -s https://archive.apache.org/dist/spark/spark-2.3.3/spark-2.3.3-bin-hadoop2.7.tgz | tar -xz -C /usr/local
RUN mv /usr/local/spark-2.3.3-bin-hadoop2.7 $SPARK_HOME

# config spark to read hive tables
RUN ln -s $HADOOP_HOME/etc/hadoop/core-site.xml $SPARK_HOME/conf/core-site.xml
RUN ln -s $HADOOP_HOME/etc/hadoop/hdfs-site.xml $SPARK_HOME/conf/hdfs-site.xml
RUN ln -s $HIVE_HOME/conf/hive-site.xml $SPARK_HOME/conf/hive-site.xml

################################################################################
# install hue
RUN mkdir $HUE_HOME
RUN curl -L https://www.dropbox.com/s/0rhrlnjmyw6bnfc/hue-4.2.0.tgz?dl=0 | tar -zx -C $HUE_HOME --strip-components 1
WORKDIR $HUE_HOME
RUN make apps

RUN rm -f $HUE_HOME/desktop/conf/hue.ini
ADD hue.ini $HUE_HOME/desktop/conf


################################################################################
# install tez
RUN mkdir $TEZ_HOME
RUN curl -L https://www.apache.org/dist/tez/0.8.5/apache-tez-0.8.5-bin.tar.gz | tar -zx -C $TEZ_HOME --strip-components 1
RUN mkdir -p /tmp/tez && \
  tar -xzvf $TEZ_HOME/share/tez.tar.gz -C /tmp/tez && \
  cp $HIVE_HOME/lib/hive-hcatalog-core*.jar /tmp/tez/lib/ && \
  cp $HIVE_HOME/lib/hive-hcatalog-server-extensions*.jar /tmp/tez/lib/ && \
  cp $HIVE_HOME/lib/hive-exec*.jar /tmp/tez/lib/ && \
  cd /tmp/tez && \
  tar -czvf /tmp/tez.tar.gz . && \
  mv /tmp/tez.tar.gz $TEZ_HOME/share/tez.tar.gz

RUN mkdir $CATALINA_HOME
RUN curl -L 'https://www.apache.org/dist/tomcat/tomcat-8/v8.5.47/bin/apache-tomcat-8.5.47.tar.gz' | tar -zx -C $CATALINA_HOME --strip-components 1
RUN mkdir -p $CATALINA_HOME/webapps/tez-ui && \
  cp $TEZ_HOME/tez-ui-0.8.5.war $CATALINA_HOME/webapps/tez-ui && \
  cd $CATALINA_HOME/webapps/tez-ui && \
  unzip tez-ui-0.8.5.war && \
  rm tez-ui-0.8.5.war

################################################################################
# add mysql jdbc driver
RUN wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.15.tar.gz
RUN tar -xzf mysql-connector-java-8.0.15.tar.gz
RUN cp mysql-connector-java-8.0.15/mysql-connector-java-8.0.15.jar $HIVE_HOME/lib
RUN cp mysql-connector-java-8.0.15/mysql-connector-java-8.0.15.jar $SPARK_HOME/jars/
RUN rm -rf mysql-connector-java-8.0.15 mysql-connector-java-8.0.15.tar.gz

################################################################################
# add users and groups
RUN groupadd hdfs && groupadd hadoop && groupadd hive && groupadd mapred && groupadd spark && groupadd tez
RUN useradd -g tez tez
RUN useradd -g hadoop hdpu && echo "hdpu:hdpu123" | chpasswd && adduser hdpu sudo
RUN usermod -s /bin/bash hdpu

RUN usermod -a -G hdfs hdpu
RUN usermod -a -G hadoop hdpu
RUN usermod -a -G hive hdpu
RUN usermod -a -G mapred hdpu
RUN usermod -a -G spark hdpu
RUN usermod -a -G tez hdpu

RUN mkdir /home/hdpu
RUN chown -R hdpu:hadoop /home/hdpu
RUN echo "source /home/hdpu/.bashrc" > /home/hdpu/.profile
ADD bashrc /home/hdpu/.bashrc
RUN chown hdpu:hadoop /home/hdpu/.bashrc /home/hdpu/.profile
ADD tez-site.xml /etc/tez/conf/tez-site.xml

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

# Timeline Server
EXPOSE 8188

# Tomcat
EXPOSE 8080
################################################################################
# create startup script and set ENTRYPOINT
WORKDIR /
ADD start.sh /usr/local/sbin
ENTRYPOINT /bin/bash /usr/local/sbin/start.sh
