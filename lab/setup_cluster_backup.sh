#!/bin/bash

# NODES=("10.0.30.21" "10.0.30.22" "10.0.30.11" "10.0.30.12" "10.0.30.13")
NODES=("10.0.30.21" "10.0.30.22")

JAVA_TAR="OpenJDK8U-jdk_x64_linux_hotspot_8u212b04.tar.gz"
HADOOP_TAR="hadoop-3.3.1.tar.gz"
HIVE_TAR="apache-hive-3.1.2-bin.tar.gz"
SPARK_TAR="spark-3.1.2-bin-hadoop3.2.tgz"

JAVA_URL="https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u212-b04/OpenJDK8U-jdk_x64_linux_hotspot_8u212b04.tar.gz"
HADOOP_URL="https://archive.apache.org/dist/hadoop/core/hadoop-3.3.1/hadoop-3.3.1.tar.gz"
HIVE_URL="https://archive.apache.org/dist/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz"
SPARK_URL="https://archive.apache.org/dist/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz"

INSTALL_DIR="/opt"

JAVA_DIR="jdk8u212-b04"
HADOOP_DIR="hadoop-3.3.1"
HIVE_DIR="apache-hive-3.1.2-bin"
SPARK_DIR="spark-3.1.2-bin-hadoop3.2"

# HDFS_USER="hdfs"
# YARN_USER="yarn"
HDFS_USER="root"
YARN_USER="root"

log() {
  local message="$1"
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $message"
}

create_users() {
  log "Creating users on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Creating $HDFS_USER and $YARN_USER on $NODE"
    ssh $NODE "sudo useradd -m $HDFS_USER || echo 'User $HDFS_USER already exists'"
    ssh $NODE "sudo useradd -m $YARN_USER || echo 'User $YARN_USER already exists'"
  done
  log "User creation completed."
}

setup_ssh_for_hdfs() {
  log "Setting up SSH for hdfs user..."
  sudo -u $HDFS_USER ssh-keygen -t rsa -P "" -f /home/$HDFS_USER/.ssh/id_rsa
  for NODE in "${NODES[@]}"; do
    log "Copying SSH key to $NODE for hdfs user"
    ssh-copy-id -i /home/$HDFS_USER/.ssh/id_rsa.pub $HDFS_USER@$NODE
    ssh $NODE "sudo chown -R $HDFS_USER:$HDFS_USER /home/$HDFS_USER/.ssh"
    ssh $NODE "sudo chmod 700 /home/$HDFS_USER/.ssh"
    ssh $NODE "sudo chmod 600 /home/$HDFS_USER/.ssh/authorized_keys"
  done
  log "SSH setup for hdfs user completed."
}

setup_ssh_for_yarn() {
  log "Setting up SSH for yarn user..."
  sudo -u $YARN_USER ssh-keygen -t rsa -P "" -f /home/$YARN_USER/.ssh/id_rsa
  for NODE in "${NODES[@]}"; do
    log "Copying SSH key to $NODE for yarn user"
    ssh-copy-id -i /home/$YARN_USER/.ssh/id_rsa.pub $YARN_USER@$NODE
    ssh $NODE "sudo chown -R $YARN_USER:$YARN_USER /home/$YARN_USER/.ssh"
    ssh $NODE "sudo chmod 700 /home/$YARN_USER/.ssh"
    ssh $NODE "sudo chmod 600 /home/$YARN_USER/.ssh/authorized_keys"
  done
  log "SSH setup for yarn user completed."
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
  log "File download completed."
}

setup_ssh() {
  log "Setting up SSH..."
  ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
  for NODE in "${NODES[@]}"; do
    log "Copying SSH key to ${NODE}"
    ssh-copy-id -i ~/.ssh/id_rsa.pub $NODE
  done
  log "SSH setup completed."
}

install_java() {
  log "Installing Java on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Installing Java on $NODE"
    scp $JAVA_TAR $NODE:$INSTALL_DIR
    ssh $NODE "tar -xzf $INSTALL_DIR/$JAVA_TAR -C $INSTALL_DIR"
    ssh $NODE "echo 'export JAVA_HOME=$INSTALL_DIR/$JAVA_DIR' >> ~/.bashrc"
    ssh $NODE "source ~/.bashrc"
    ssh $NODE "echo $JAVA_HOME"
  done
  log "Java installation completed."
}

install_hadoop() {
  log "Installing Hadoop on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Installing Hadoop on $NODE"
    scp $HADOOP_TAR $NODE:$INSTALL_DIR
    ssh $NODE "tar -xzf $INSTALL_DIR/$HADOOP_TAR -C $INSTALL_DIR"
  done
  log "Hadoop installation completed."
}

install_hive() {
  log "Installing Hive on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Installing Hive on $NODE"
    scp $HIVE_TAR $NODE:$INSTALL_DIR
    ssh $NODE "tar -xzf $INSTALL_DIR/$HIVE_TAR -C $INSTALL_DIR"
  done
  log "Hive installation completed."
}

install_spark() {
  log "Installing Spark on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Installing Spark on $NODE"
    scp $SPARK_TAR $NODE:$INSTALL_DIR
    ssh $NODE "tar -xzf $INSTALL_DIR/$SPARK_TAR -C $INSTALL_DIR"
  done
  log "Spark installation completed."
}

configure_environment() {
  log "Configuring environment variables on all nodes..."
  for NODE in "${NODES[@]}"; do
    log "Configuring environment on $NODE"
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

configure_hadoop() {
  log "Configuring Hadoop on the master node..."
  
  cp $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/core-site.xml $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/core-site.xml.bak
  cat <<EOT > $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/core-site.xml
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://$(hostname -I | awk '{print $1}'):9000</value>
  </property>
</configuration>
EOT

  cp $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/hdfs-site.xml $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/hdfs-site.xml.bak
  cat <<EOT > $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/hdfs-site.xml
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>2</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///usr/local/hadoop/hadoop_data/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///usr/local/hadoop/hadoop_data/hdfs/datanode</value>
  </property>
</configuration>
EOT

  cp $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/mapred-site.xml.template $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/mapred-site.xml
  cat <<EOT > $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/mapred-site.xml
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>
EOT

  cp $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/yarn-site.xml $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/yarn-site.xml.bak
  cat <<EOT > $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/yarn-site.xml
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
  </property>
</configuration>
EOT

  log "Copying Hadoop configuration to all slave nodes..."
  for NODE in "${NODES[@]}"; do
    if [ "$NODE" != "$(hostname -I | awk '{print $1}')" ]; then
      scp $INSTALL_DIR/$HADOOP_DIR/etc/hadoop/*.xml $NODE:$INSTALL_DIR/$HADOOP_DIR/etc/hadoop/
    fi
  done

  log "Creating Hadoop directories on all nodes..."
  for NODE in "${NODES[@]}"; do
    ssh $NODE "mkdir -p /usr/local/hadoop/hadoop_data/hdfs/namenode"
    ssh $NODE "mkdir -p /usr/local/hadoop/hadoop_data/hdfs/datanode"
  done

  log "Formatting the Hadoop namenode..."
  $INSTALL_DIR/$HADOOP_DIR/bin/hdfs namenode -format

  log "Starting HDFS and YARN services..."
  source ~/.bashrc
  $INSTALL_DIR/$HADOOP_DIR/sbin/start-dfs.sh
  $INSTALL_DIR/$HADOOP_DIR/sbin/start-yarn.sh

  log "Hadoop configuration completed."

  # Configure hadoop-env.sh on all nodes
  configure_hadoop_env
}

main() {
  # Uncomment the following lines to enable each step as needed
  #create_users
  #setup_ssh_for_hdfs
  #setup_ssh_for_yarn
  download_files
  # setup_ssh
  install_java
  install_hadoop
  install_hive
  install_spark
  configure_environment
  configure_hadoop
}

main
