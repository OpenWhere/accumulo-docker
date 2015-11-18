FROM sequenceiq/hadoop-docker

MAINTAINER @singram <singram@openwhere.com>

USER root

ENV PATH $PATH:$HADOOP_PREFIX/bin

ENV ACCUMULO_VERSION 1.7.0
ENV ZOOKEEPER_VERSION 3.4.6
ENV SPARK_VERSION 1.5.2
ENV SPARK_BIN_TYPE hadoop2.6

RUN chown -R root:root $HADOOP_PREFIX

RUN echo -e "\n* soft nofile 65536\n* hard nofile 65536" >> /etc/security/limits.conf
RUN echo -e "vm.swappiness=10" >> /etc/sysctl.conf

RUN curl -s http://mirror.cc.columbia.edu/pub/software/apache/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz | tar -xz -C /usr/local
RUN ln -s /usr/local/zookeeper-$ZOOKEEPER_VERSION /usr/local/zookeeper;\
 chown -R root:root /usr/local/zookeeper-$ZOOKEEPER_VERSION;\
 mkdir -p /var/zookeeper
ENV ZOOKEEPER_HOME /usr/local/zookeeper
ENV PATH $PATH:$ZOOKEEPER_HOME/bin
ADD zookeeper/* $ZOOKEEPER_HOME/conf/

ADD scala/* /tmp/
RUN rpm -i /tmp/scala-2.10.6.rpm
RUN rm /tmp/scala-2.10.6.rpm

RUN curl -s http://mirror.cc.columbia.edu/pub/software/apache/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-$SPARK_BIN_TYPE.tgz | tar -xz -C /usr/local
RUN ln -s /usr/local/spark-$SPARK_VERSION-bin-$SPARK_BIN_TYPE /usr/local/spark;\
  chown -R root:root /usr/local/spark-$SPARK_VERSION-bin-$SPARK_BIN_TYPE
ENV SPARK_HOME /usr/local/spark
ENV PATH $PATH:$SPARK_HOME/bin

RUN curl -s http://archive.apache.org/dist/accumulo/$ACCUMULO_VERSION/accumulo-$ACCUMULO_VERSION-bin.tar.gz | tar -xz -C /usr/local
RUN ln -s /usr/local/accumulo-$ACCUMULO_VERSION /usr/local/accumulo;\
 chown -R root:root /usr/local/accumulo-$ACCUMULO_VERSION
ENV ACCUMULO_HOME /usr/local/accumulo
ENV PATH $PATH:$ACCUMULO_HOME/bin
ADD accumulo/* $ACCUMULO_HOME/conf/

ADD hadoop/* /tmp/hadoopsource/
ADD spark/* /usr/local/spark/conf/
RUN chmod 700 /usr/local/spark/conf/spark-env.sh

ADD *-all.sh /etc/
RUN chown root:root /etc/*-all.sh;\
 chmod 700 /etc/*-all.sh

ADD run-hadoop.sh /etc/
RUN chmod 700 /etc/run-hadoop.sh

ADD startup/accumulo /etc/init.d/
RUN chmod 700 /etc/init.d/accumulo;\
 chkconfig --add accumulo

CMD ["/bin/bash", "/etc/run-all.sh", "infinity"]

EXPOSE 9000 50095 50070 8088 7077 4040
