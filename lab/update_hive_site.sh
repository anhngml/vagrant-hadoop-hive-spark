#!/bin/bash

NODES=("10.0.30.21" "10.0.30.22" "10.0.30.11" "10.0.30.12" "10.0.30.13")

INSTALL_DIR="/opt"

JAVA_DIR="jdk8u212-b04"
HADOOP_DIR="hadoop-3.3.1"
HIVE_DIR="apache-hive-3.1.2-bin"
SPARK_DIR="spark-3.1.2-bin-hadoop3.2"

HDFS_USER="root"
YARN_USER="root"


log() {
  local message="$1"
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $message"
}

stop_hive() {
  log "Stopping Hive on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Stopping Hive services on $NODE"
    ssh $NODE "pkill -f HiveMetaStore"
    ssh $NODE "pkill -f HiveServer2"
  done
  log "Hive stopped on all nodes."
}

configure_hive() {
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

</configuration>
EOF

  # log "Initializing Hive schema on master node..."
  # ssh ${NODES[0]} "$INSTALL_DIR/$HIVE_DIR/bin/schematool -initSchema -dbType mysql"
  log "Starting Hive metastore on master node..."
  ssh ${NODES[0]} "$INSTALL_DIR/$HIVE_DIR/bin/hive --service metastore &"
  log "Starting HiveServer2 on master node..."
  ssh ${NODES[0]} "$INSTALL_DIR/$HIVE_DIR/bin/hive --service hiveserver2 &"
}
stop_hive
configure_hive

log "Done."
