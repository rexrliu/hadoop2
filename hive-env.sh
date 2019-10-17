## for tez

export TEZ_HOME=/usr/local/tez
export TEZ_CONF_DIR=$TEZ_HOME/conf
export HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${TEZ_CONF_DIR}:${TEZ_HOME}/*:${TEZ_HOME}/lib/*
