#!/bin/bash

set -e


master() {
    echo "Waiting 10 seconds for slaves to start up"
    sleep 10
    $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
    rm /tmp/*.pid
    cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

    zkhost=$1
    mhost=$2
    declare -a slaves=("${!3}")

    sed "s/HOSTNAME/$mhost/g" /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
    sed "s/HOSTNAME/$mhost/g" /usr/local/accumulo/conf/accumulo-site-template.xml > /usr/local/accumulo/conf/accumulo-site.xml.tmp
    sed "s/ZOOKEEPERHOST/$zkhost/g" /usr/local/accumulo/conf/accumulo-site.xml.tmp > /usr/local/accumulo/conf/accumulo-site.xml
    rm -f /usr/local/accumulo/conf/accumulo-site.xml.tmp
    cp -f /tmp/hadoopsource/hdfs-site-master-template.xml /usr/local/hadoop/etc/hadoop/hdfs-site.xml
    sed "s/HOSTNAME/$mhost/g" /tmp/hadoopsource/yarn-site-template.xml > /usr/local/hadoop/etc/hadoop/yarn-site.xml
    mkdir -p /usr/local/hadoop/hadoop_data/hdfs/namenode

    echo $mhost > /usr/local/accumulo/conf/gc
    echo $mhost > /usr/local/accumulo/conf/masters
    echo $mhost > /usr/local/accumulo/conf/monitor
    echo $mhost > /usr/local/accumulo/conf/slaves
    echo $mhost > /usr/local/accumulo/conf/tracers
    echo $mhost > /usr/local/hadoop/etc/hadoop/masters
    echo $mhost > /usr/local/hadoop/etc/hadoop/slaves
    for slave in "${slaves[@]}"
      do
        echo $slave >> /usr/local/hadoop/etc/hadoop/slaves
        echo $slave >> /usr/local/accumulo/conf/slaves
        echo $slave >> /usr/local/accumulo/conf/tracers
      done

    service sshd start
    $HADOOP_PREFIX/bin/hdfs namenode -format
    $HADOOP_PREFIX/sbin/start-dfs.sh
    echo "Waiting 5 seconds for DFS to start up:"
    netstat -an | grep LISTEN
    sleep 5
    $HADOOP_PREFIX/bin/hdfs dfsadmin -safemode wait
    $HADOOP_PREFIX/sbin/start-yarn.sh
    if [ ! -f /usr/local/accumulo/.isinit ]; then
      /usr/local/accumulo/bin/accumulo init --instance-name accumulo --password secret
      echo "true" >  /usr/local/accumulo/.isinit
    fi
    /usr/local/accumulo/bin/start-all.sh
}

slave() {
    $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
    rm /tmp/*.pid
    cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

    zkhost=$1
    mhost=$2
    declare -a slaves=("${!3}")

    sed "s/HOSTNAME/$mhost/g" /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
    sed "s/HOSTNAME/$mhost/g" /usr/local/accumulo/conf/accumulo-site-template.xml > /usr/local/accumulo/conf/accumulo-site.xml.tmp
    sed "s/ZOOKEEPERHOST/$zkhost/g" /usr/local/accumulo/conf/accumulo-site.xml.tmp > /usr/local/accumulo/conf/accumulo-site.xml
    rm -f /usr/local/accumulo/conf/accumulo-site.xml.tmp
    cp -f /tmp/hadoopsource/hdfs-site-slave-template.xml /usr/local/hadoop/etc/hadoop/hdfs-site.xml
    sed "s/HOSTNAME/$mhost/g" /tmp/hadoopsource/yarn-site-template.xml > /usr/local/hadoop/etc/hadoop/yarn-site.xml
    sed "s/HOSTNAME/$mhost/g" /tmp/hadoopsource/mapred-site-template.xml > /usr/local/hadoop/etc/hadoop/mapred-site.xml
    mkdir -p /usr/local/hadoop/hadoop_data/hdfs/datanode
    rm -f /root/.ssh/id_rsa*
    rm -f  /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_rsa_key
    ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
    ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
    ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa

    echo $mhost > /usr/local/accumulo/conf/gc
    echo $mhost > /usr/local/accumulo/conf/masters
    echo $mhost > /usr/local/accumulo/conf/monitor
    echo $mhost > /usr/local/accumulo/conf/slaves
    echo $mhost > /usr/local/accumulo/conf/tracers
    echo $mhost > /usr/local/hadoop/etc/hadoop/masters
    echo $mhost > /usr/local/hadoop/etc/hadoop/slaves
    echo
    for slave in "${slaves[@]}"
      do
        echo $slave >> /usr/local/hadoop/etc/hadoop/slaves
        echo $slave >> /usr/local/accumulo/conf/slaves
        echo $slave >> /usr/local/accumulo/conf/tracers
      done
    service sshd start
}

listargs() {
  zkhost=$1
  mhost=$2
  declare -a slaves=("${!3}")
  echo "master=$mhost, slaves=${slaves[@]}"
  for slave in "${slaves[@]}"
    do
      echo "$slave"
    done
}

mode=$1
zookeeper=$2
masterhost=$3
hosts=($4 $5 $6 $7 $8 $9)
echo "hosts=${hosts[@]}"
case $mode in
  master)
        master $zookeeper $masterhost hosts[@]
        echo "sleeping $HOSTNAME"
        while true; do sleep 1000; done
        ;;
  slave)
        slave $zookeeper $masterhost hosts[@]
        echo "sleeping $HOSTNAME"
        while true; do sleep 1000; done
        ;;
  *)
        echo "usage: $0 master|slave zookeeper masterhost slavehost(s)"
esac
exit 0