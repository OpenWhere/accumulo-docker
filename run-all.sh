#!/bin/bash

listenv() {
  echo "JAVA_HOME=$JAVA_HOME"
  echo "HADOOP_PREFIX=$HADOOP_PREFIX"
  echo "ACCUMULO_HOME=$ACCUMULO_HOME"
}
infinity() {
service accumulo start
echo "Running until killed"
while true
  do
    sleep 300
  done
}

minutes() {
service accumulo start
minute="0"
t=${1:-120}
sleep 90
echo "Sleeping for $t minutes"
while [ $minute -lt $t ]
 do
    sleep 60
    echo "$minute of $t minutes"
    minute=`expr $minute + 1`
 done
}

opt=$1
case $opt in
  infinity)
        infinity
        ;;
  *)
        minutes $1
 esac
exit 0