#!/bin/bash

NODES=("10.0.30.21" "10.0.30.22" "10.0.30.11" "10.0.30.12" "10.0.30.13")
# NODES=("10.0.30.21" "10.0.30.22")
# 10.0.30.21 mkdc-master01
# 10.0.30.22 mkdc-psvr-master-02
# 10.0.30.11 mkdc-psvr-slave-01
# 10.0.30.12 mkdc-psvr-slave-02
# 10.0.30.13 mkdc-psvr-slave-03
NODE_NAMES=("mkdc-master01" "mkdc-psvr-master-02" "mkdc-psvr-slave-01" "mkdc-psvr-slave-02" "mkdc-psvr-slave-03")


JAVA_TAR="OpenJDK8U-jdk_x64_linux_hotspot_8u212b04.tar.gz"
HADOOP_TAR="hadoop-3.3.1.tar.gz"
HIVE_TAR="apache-hive-3.1.2-bin.tar.gz"
SPARK_TAR="spark-3.1.2-bin-hadoop3.2.tgz"
JDBC_JAR="mysql-connector-java-8.0.26.jar"

JAVA_URL="https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u212-b04/OpenJDK8U-jdk_x64_linux_hotspot_8u212b04.tar.gz"
HADOOP_URL="https://archive.apache.org/dist/hadoop/core/hadoop-3.3.1/hadoop-3.3.1.tar.gz"
HIVE_URL="https://archive.apache.org/dist/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz"
SPARK_URL="https://archive.apache.org/dist/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz"
JDBC_URL="https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.26.tar.gz"

INSTALL_DIR="/opt"

JAVA_DIR="jdk8u212-b04"
HADOOP_DIR="hadoop-3.3.1"
HIVE_DIR="apache-hive-3.1.2-bin"
SPARK_DIR="spark-3.1.2-bin-hadoop3.2"

HDFS_USER="root"
YARN_USER="root"

# HDFS_DATA_DIR = 'opt/hadoop_data'
HDFS_DATA_DIR = 'mnt/data/hadoop_data'

log() {
  local message="$1"
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $message"
}

download_files() {
  log "Starting file download..."
  if [ ! -f "$JAVA_TAR" ]; then
    log "Downloading Java..."
    wget -O $JAVA_TAR $JAVA_URL
  fi

  if [ ! -f "$HADOOP_TAR" ]; then
    log "Downloading Hadoop..."
    wget -O $HADOOP_TAR $HADOOP_URL
  fi

  if [ ! -f "$HIVE_TAR" ]; then
    log "Downloading Hive..."
    wget -O $HIVE_TAR $HIVE_URL
  fi

  if [ ! -f "$SPARK_TAR" ]; then
    log "Downloading Spark..."
    wget -O $SPARK_TAR $SPARK_URL
  fi

  if [ ! -f "$JDBC_JAR" ]; then
    log "Downloading JDBC driver..."
    wget -O mysql-connector-java.tar.gz $JDBC_URL
    tar -xzf mysql-connector-java.tar.gz
    cp mysql-connector-java-*/mysql-connector-java-*.jar $JDBC_JAR
  fi

  log "File download completed."
}

install_java() {
  log "Installing Java on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Installing Java on $NODE"
    scp $JAVA_TAR $NODE:$INSTALL_DIR
    ssh $NODE "tar -xzf $INSTALL_DIR/$JAVA_TAR -C $INSTALL_DIR"
    # ssh $NODE "echo 'export JAVA_HOME=$INSTALL_DIR/$JAVA_DIR' >> ~/.bashrc"
    # ssh $NODE "echo 'export PATH=\$JAVA_HOME/bin:\$PATH' >> ~/.bashrc"
    # ssh $NODE "source ~/.bashrc"
    # ssh $NODE "echo $JAVA_HOME"
  done
  log "Java installation completed."
}

install_hadoop() {
  log "Installing Hadoop on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Installing Hadoop on $NODE"
    scp $HADOOP_TAR $NODE:$INSTALL_DIR
    ssh $NODE "tar -xzf $INSTALL_DIR/$HADOOP_TAR -C $INSTALL_DIR"
    # ssh $NODE "echo 'export HADOOP_HOME=$INSTALL_DIR/$HADOOP_DIR' >> ~/.bashrc"
    # ssh $NODE "echo 'export PATH=\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$PATH' >> ~/.bashrc"
    # ssh $NODE "source ~/.bashrc"
  done
  log "Hadoop installation completed."
}

install_hive() {
  log "Installing Hive on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Installing Hive on $NODE"
    scp $HIVE_TAR $NODE:$INSTALL_DIR
    ssh $NODE "tar -xzf $INSTALL_DIR/$HIVE_TAR -C $INSTALL_DIR"
    scp $JDBC_JAR $NODE:$INSTALL_DIR/$HIVE_DIR/lib/
    # ssh $NODE "echo 'export HIVE_HOME=$INSTALL_DIR/$HIVE_DIR' >> ~/.bashrc"
    # ssh $NODE "echo 'export PATH=\$HIVE_HOME/bin:\$PATH' >> ~/.bashrc"
    # ssh $NODE "source ~/.bashrc"
  done
  log "Hive installation completed."
}

install_spark() {
  log "Installing Spark on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Installing Spark on $NODE"
    scp $SPARK_TAR $NODE:$INSTALL_DIR
    ssh $NODE "tar -xzf $INSTALL_DIR/$SPARK_TAR -C $INSTALL_DIR"
    # ssh $NODE "echo 'export SPARK_HOME=$INSTALL_DIR/$SPARK_DIR' >> ~/.bashrc"
    # ssh $NODE "echo 'export PATH=\$SPARK_HOME/bin:\$PATH' >> ~/.bashrc"
    # ssh $NODE "source ~/.bashrc"
  done
  log "Spark installation completed."
}

configure_environment() {
  log "Configuring environment variables on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Configuring environment on $NODE"
    # Remove existing definitions if they exist
    ssh $NODE "sed -i '/export JAVA_HOME=/d' ~/.bashrc"
    ssh $NODE "sed -i '/export HADOOP_HOME=/d' ~/.bashrc"
    ssh $NODE "sed -i '/export HIVE_HOME=/d' ~/.bashrc"
    ssh $NODE "sed -i '/export SPARK_HOME=/d' ~/.bashrc"
    ssh $NODE "sed -i '/export PATH=\$JAVA_HOME\/bin:\$HADOOP_HOME\/bin:\$HADOOP_HOME\/sbin:\$HIVE_HOME\/bin:\$SPARK_HOME\/bin:\$PATH/d' ~/.bashrc"

    ssh $NODE "echo 'export JAVA_HOME=$INSTALL_DIR/$JAVA_DIR' >> ~/.bashrc"
    ssh $NODE "echo 'export HADOOP_HOME=$INSTALL_DIR/$HADOOP_DIR' >> ~/.bashrc"
    ssh $NODE "echo 'export HIVE_HOME=$INSTALL_DIR/$HIVE_DIR' >> ~/.bashrc"
    ssh $NODE "echo 'export SPARK_HOME=$INSTALL_DIR/$SPARK_DIR' >> ~/.bashrc"
    ssh $NODE "echo 'export PATH=\$JAVA_HOME/bin:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$HIVE_HOME/bin:\$SPARK_HOME/bin:\$PATH' >> ~/.bashrc"
    
    ssh $NODE "sed -i '/export HDFS_NAMENODE_USER=/d' ~/.bashrc"
    ssh $NODE "sed -i '/export HDFS_DATANODE_USER=/d' ~/.bashrc"
    ssh $NODE "sed -i '/export HDFS_SECONDARYNAMENODE_USER=/d' ~/.bashrc"
    ssh $NODE "sed -i '/export HADOOP_SECURE_DN_USER=/d' ~/.bashrc"
    ssh $NODE "sed -i '/export YARN_NODEMANAGER_USER=/d' ~/.bashrc"
    ssh $NODE "sed -i '/export YARN_RESOURCEMANAGER_USER=/d' ~/.bashrc"

    ssh $NODE "echo 'export HDFS_NAMENODE_USER=$HDFS_USER' >> ~/.bashrc"
    ssh $NODE "echo 'export HDFS_DATANODE_USER=$HDFS_USER' >> ~/.bashrc"
    ssh $NODE "echo 'export HDFS_SECONDARYNAMENODE_USER=$HDFS_USER' >> ~/.bashrc"
    ssh $NODE "echo 'export HADOOP_SECURE_DN_USER=$HDFS_USER' >> ~/.bashrc"
    ssh $NODE "echo 'export YARN_NODEMANAGER_USER=$YARN_USER' >> ~/.bashrc"
    ssh $NODE "echo 'export YARN_RESOURCEMANAGER_USER=$YARN_USER' >> ~/.bashrc"
    
    ssh $NODE "source ~/.bashrc"
  done
  log "Environment configuration completed."
}

configure_hadoop_env() {
  log "Configuring Hadoop environment variables on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Configuring Hadoop environment on $NODE"
    ssh $NODE "echo 'export JAVA_HOME=$INSTALL_DIR/$JAVA_DIR' >> $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/hadoop-env.sh"
    # export HDFS_NAMENODE_USER="root"
    # export HDFS_DATANODE_USER="root"
    # export HDFS_SECONDARYNAMENODE_USER="root"
    # export YARN_RESOURCEMANAGER_USER="root"
    # export YARN_NODEMANAGER_USER="root"
    ssh $NODE "echo 'export HDFS_NAMENODE_USER=$HDFS_USER' >> $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/hadoop-env.sh"
    ssh $NODE "echo 'export HDFS_DATANODE_USER=$HDFS_USER' >> $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/hadoop-env.sh"
    ssh $NODE "echo 'export HDFS_SECONDARYNAMENODE_USER=$HDFS_USER' >> $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/hadoop-env.sh"
    ssh $NODE "echo 'export YARN_RESOURCEMANAGER_USER=$YARN_USER' >> $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/hadoop-env.sh"
    ssh $NODE "echo 'export YARN_NODEMANAGER_USER=$YARN_USER' >> $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/hadoop-env.sh"
  done
  log "Hadoop environment configuration completed."
}

configure_dfs_scripts() {
  log "Configuring start-dfs.sh and stop-dfs.sh scripts on all nodes..."
  for NODE in "${NODES[@]}"; do
    ssh $NODE "echo 'export HDFS_NAMENODE_USER=$HDFS_USER' >> $INSTALL_DIR/$HADOOP_DIR/sbin/start-dfs.sh"
    ssh $NODE "echo 'export HDFS_DATANODE_USER=$HDFS_USER' >> $INSTALL_DIR/$HADOOP_DIR/sbin/start-dfs.sh"
    ssh $NODE "echo 'export HDFS_SECONDARYNAMENODE_USER=$HDFS_USER' >> $INSTALL_DIR/$HADOOP_DIR/sbin/start-dfs.sh"
    ssh $NODE "echo 'export HDFS_NAMENODE_USER=$HDFS_USER' >> $INSTALL_DIR/$HADOOP_DIR/sbin/stop-dfs.sh"
    ssh $NODE "echo 'export HDFS_DATANODE_USER=$HDFS_USER' >> $INSTALL_DIR/$HADOOP_DIR/sbin/stop-dfs.sh"
    ssh $NODE "echo 'export HDFS_SECONDARYNAMENODE_USER=$HDFS_USER' >> $INSTALL_DIR/$HADOOP_DIR/sbin/stop-dfs.sh"
  done
  log "start-dfs.sh and stop-dfs.sh scripts configuration completed."
}

configure_yarn_scripts() {
  log "Configuring start-yarn.sh and stop-yarn.sh scripts on all nodes..."
  for NODE in "${NODES[@]}"; do
    ssh $NODE "echo 'export YARN_RESOURCEMANAGER_USER=$YARN_USER' >> $INSTALL_DIR/$HADOOP_DIR/sbin/start-yarn.sh"
    ssh $NODE "echo 'export YARN_NODEMANAGER_USER=$YARN_USER' >> $INSTALL_DIR/$HADOOP_DIR/sbin/start-yarn.sh"
    ssh $NODE "echo 'export YARN_RESOURCEMANAGER_USER=$YARN_USER' >> $INSTALL_DIR/$HADOOP_DIR/sbin/stop-yarn.sh"
    ssh $NODE "echo 'export YARN_NODEMANAGER_USER=$YARN_USER' >> $INSTALL_DIR/$HADOOP_DIR/sbin/stop-yarn.sh"
  done
  log "start-yarn.sh and stop-yarn.sh scripts configuration completed."
}

update_hosts() {
  log "Updating /etc/hosts on all nodes..."
  for NODE in "${NODES[@]}"; do
    for OTHER_NODE in "${NODES[@]}"; do
      HOSTNAME=$(ssh $OTHER_NODE "hostname")
      ssh $NODE "echo '${OTHER_NODE} ${HOSTNAME}' >> /etc/hosts"
    done
  done
  log "/etc/hosts update completed."
}


configure_hadoop() {
  configure_hadoop_env
  configure_dfs_scripts
  configure_yarn_scripts
  # update_hosts
  log "Configuring Hadoop on the master node..."
  cat <<EOF | ssh ${NODES[0]} "cat > $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/core-site.xml"
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://${NODES[0]}:9000</value>
  </property>
  <property>
    <name>hadoop.proxyuser.root.hosts</name>
    <value>*</value>
    <description>Allow root to impersonate from any host</description>
  </property>
  <property>
    <name>hadoop.proxyuser.root.groups</name>
    <value>*</value>
    <description>Allow root to impersonate any group</description>
  </property>
</configuration>
EOF

  cat <<EOF | ssh ${NODES[0]} "cat > $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/hdfs-site.xml"
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>3</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///opt/hadoop_data/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///opt/hadoop_data/hdfs/datanode</value>
  </property>
</configuration>
EOF

  cat <<EOF | ssh ${NODES[0]} "cat > $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/yarn-site.xml"
<configuration>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>${NODES[0]}</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
</configuration>
EOF

  cat <<EOF | ssh ${NODES[0]} "cat > $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/mapred-site.xml"
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
    <property>
    <name>yarn.app.mapreduce.am.resource.mb</name>
    <value>512</value>
  </property>
  <property>
    <name>mapreduce.map.memory.mb</name>
    <value>256</value>
  </property>
  <property>
    <name>mapreduce.reduce.memory.mb</name>
    <value>256</value>
  </property>
  <property>
    <name>yarn.app.mapreduce.am.env</name>
    <value>HADOOP_MAPRED_HOME=$HADOOP_HOME</value>
  </property>
  <property>
    <name>mapreduce.map.env</name>
    <value>HADOOP_MAPRED_HOME=$HADOOP_HOME</value>
  </property>
  <property>
    <name>mapreduce.reduce.env</name>
    <value>HADOOP_MAPRED_HOME=$HADOOP_HOME</value>
  </property>
</configuration>
EOF

  log "Configuring Hadoop slaves..."
  ssh ${NODES[0]} "cp /dev/null > $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/workers"
  for NODE in "${NODES[@]}"; do
    echo $NODE | ssh ${NODES[0]} "cat >> $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/workers"
  done

  log "Copying Hadoop configuration to slave nodes..."
  for NODE in "${NODES[@]:1}"; do
    scp ${NODES[0]}:$INSTALL_DIR/$HADOOP_DIR/etc/hadoop/* $NODE:$INSTALL_DIR/$HADOOP_DIR/etc/hadoop/
  done

  log "Creating Hadoop data directories on all nodes..."
  for NODE in "${NODES[@]}"; do
    ssh $NODE "rm -rf /opt/hadoop_data"
    ssh $NODE "mkdir -p /opt/hadoop_data/hdfs/namenode"
    ssh $NODE "mkdir -p /opt/hadoop_data/hdfs/datanode"
  done

  # log "Formatting Hadoop namenode on the master node..."
  ssh ${NODES[0]} "export JAVA_HOME=$INSTALL_DIR/$JAVA_DIR && $INSTALL_DIR/$HADOOP_DIR/bin/hdfs namenode -format"

  # log "Starting Hadoop services on the master node..."
  # ssh ${NODES[0]} "export JAVA_HOME=$INSTALL_DIR/$JAVA_DIR && $INSTALL_DIR/$HADOOP_DIR/sbin/start-dfs.sh"
  # ssh ${NODES[0]} "export JAVA_HOME=$INSTALL_DIR/$JAVA_DIR && $INSTALL_DIR/$HADOOP_DIR/sbin/start-yarn.sh"

  export HDFS_NAMENODE_USER="root"
  export HDFS_DATANODE_USER="root"
  export HDFS_SECONDARYNAMENODE_USER="root"
  export YARN_RESOURCEMANAGER_USER="root"
  export YARN_NODEMANAGER_USER="root"

  $INSTALL_DIR/$HADOOP_DIR/sbin/start-dfs.sh
  $INSTALL_DIR/$HADOOP_DIR/sbin/start-yarn.sh
  # log "Starting DataNode daemons on all nodes..."
  # for NODE in "${NODES[@]}"; do
  #   ssh $NODE "$INSTALL_DIR/$HADOOP_DIR/bin/hadoop-daemon.sh start datanode"
  # done
}

configure_hive_env() {
  log "Configuring Hive environment variables on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Configuring Hive environment on $NODE"
    ssh $NODE "echo 'export HADOOP_HOME=$INSTALL_DIR/$HADOOP_DIR' >> $INSTALL_DIR/$HIVE_DIR/conf/hive-env.sh"
  done
  log "Hive environment configuration completed."
}

configure_hive() {
  configure_hive_env
  log "Configuring Hive on the master node..."
  cat <<EOF | ssh ${NODES[0]} "cat > $INSTALL_DIR/$HIVE_DIR/conf/hive-site.xml"
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://localhost:3306/metastore?createDatabaseIfNotExist=true</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>com.mysql.cj.jdbc.Driver</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>hiveuser</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>hivepassword</value>
  </property>
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/user/hive/warehouse</value>
  </property>
  <property>
    <name>hive.exec.scratchdir</name>
    <value>/tmp/hive</value>
  </property>
  <property>
    <name>hive.server2.thrift.port</name>
    <value>10000</value>
    <description>Port number for HiveServer2 Thrift interface</description>
  </property>

  <property>
      <name>hive.server2.thrift.bind.host</name>
      <value>0.0.0.0</value>
      <description>Host address for HiveServer2 Thrift interface</description>
  </property>

  <property>
      <name>hive.server2.thrift.sasl.enabled</name>
      <value>false</value>
      <description>Enable SASL for HiveServer2 Thrift interface</description>
  </property>
  <property>
      <name>hive.server2.enable.doAs</name>
      <value>true</value>
      <description>Enable user impersonation in HiveServer2</description>
  </property>
  <property>
    <name>hive.server2.authentication</name>
    <value>NONE</value>
  </property>

</configuration>
EOF

  log "Initializing Hive schema on master node..."
  ssh ${NODES[0]} "$INSTALL_DIR/$HIVE_DIR/bin/schematool -initSchema -dbType mysql"
  log "Starting Hive metastore on master node..."
  ssh ${NODES[0]} "$INSTALL_DIR/$HIVE_DIR/bin/hive --service metastore &"
  log "Starting HiveServer2 on master node..."
  ssh ${NODES[0]} "$INSTALL_DIR/$HIVE_DIR/bin/hive --service hiveserver2 &"
}

configure_spark_with_hive() {
  log "Configuring Spark with Hive support on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Copying hive-site.xml to Spark configuration on $NODE"
    scp ${NODES[0]}:$INSTALL_DIR/$HIVE_DIR/conf/hive-site.xml $NODE:$INSTALL_DIR/$SPARK_DIR/conf/

    HIVE_JDBC_JAR="hive-jdbc-3.1.2-standalone.jar"
    HIVE_JDBC_URL="https://repo1.maven.org/maven2/org/apache/hive/hive-jdbc/3.1.2/hive-jdbc-3.1.2-standalone.jar"

    if [ ! -f "$HIVE_JDBC_JAR" ]; then
      log "Downloading Hive JDBC driver..."
      wget -O $HIVE_JDBC_JAR $HIVE_JDBC_URL
    fi

    log "Copying Hive JDBC driver to $NODE"
    scp $HIVE_JDBC_JAR $NODE:$INSTALL_DIR/$SPARK_DIR/jars/
  done
  log "Spark configured with Hive support."
}

configure_spark() {
  log "Configuring Spark on the master node..."
  cat <<EOF | ssh ${NODES[0]} "cat > $INSTALL_DIR/$SPARK_DIR/conf/spark-env.sh"
export JAVA_HOME=$INSTALL_DIR/$JAVA_DIR
export HADOOP_CONF_DIR=$INSTALL_DIR/$HADOOP_DIR/etc/hadoop
export SPARK_MASTER_HOST=${NODES[0]}
export SPARK_WORKER_CORES=8
export SPARK_WORKER_MEMORY=16g
EOF

  log "Copying Spark environment configuration to slave nodes..."
  for NODE in "${NODES[@]:1}"; do
    scp ${NODES[0]}:$INSTALL_DIR/$SPARK_DIR/conf/spark-env.sh $NODE:$INSTALL_DIR/$SPARK_DIR/conf/
  done

  log "Configuring Spark slaves..."
  ssh ${NODES[0]} "cp /dev/null > $INSTALL_DIR/$SPARK_DIR/conf/slaves"
  for NODE in "${NODES[@]}"; do
    echo $NODE | ssh ${NODES[0]} "cat >> $INSTALL_DIR/$SPARK_DIR/conf/slaves"
  done

  log "Configuring Spark defaults on the master node..."
  cat <<EOF | ssh ${NODES[0]} "cat > $INSTALL_DIR/$SPARK_DIR/conf/spark-defaults.conf"
spark.master                     yarn
spark.submit.deployMode          cluster
spark.driver.memory              2g
spark.executor.memory            2g
spark.executor.cores             2
spark.yarn.jars                  hdfs://10.0.30.21:9000/user/spark/jars/*

EOF

  log "Copying Spark default configuration to slave nodes..."
  for NODE in "${NODES[@]:1}"; do
    scp ${NODES[0]}:$INSTALL_DIR/$SPARK_DIR/conf/spark-defaults.conf $NODE:$INSTALL_DIR/$SPARK_DIR/conf/
  done

  log "Starting Spark services on the master node..."
  ssh ${NODES[0]} "$INSTALL_DIR/$SPARK_DIR/sbin/start-all.sh"
}

log "Starting installation and configuration script..."

download_files
# setup_ssh
install_java
install_hadoop
install_hive
install_spark
configure_environment
configure_hadoop
configure_hive
configure_spark
configure_spark_with_hive

log "Done."
