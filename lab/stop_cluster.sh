#!/bin/bash

NODES=("10.0.30.21" "10.0.30.22" "10.0.30.11" "10.0.30.12" "10.0.30.13")
INSTALL_DIR="/opt"
JAVA_DIR="jdk8u212-b04"
HADOOP_DIR="hadoop-3.3.1"
HIVE_DIR="apache-hive-3.1.2-bin"
SPARK_DIR="spark-3.1.2-bin-hadoop3.2"

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

stop_spark() {
  log "Stopping Spark on master node..."
  ssh ${NODES[0]} "export JAVA_HOME=$INSTALL_DIR/$JAVA_DIR && $INSTALL_DIR/$SPARK_DIR/sbin/stop-all.sh"
  log "Spark stopped on master node."
}

stop_hadoop() {
  log "Stopping Hadoop on master node..."
  ssh ${NODES[0]} "export JAVA_HOME=$INSTALL_DIR/$JAVA_DIR && $INSTALL_DIR/$HADOOP_DIR/sbin/stop-yarn.sh"
  ssh ${NODES[0]} "export JAVA_HOME=$INSTALL_DIR/$JAVA_DIR && $INSTALL_DIR/$HADOOP_DIR/sbin/stop-dfs.sh"
  log "Hadoop stopped on master node."
}

log "Starting cluster shutdown script..."

stop_hive
stop_spark
stop_hadoop

log "Cluster shutdown completed."
