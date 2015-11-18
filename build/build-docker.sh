#!/bin/bash
#
# Jenkins script to build a docker image for this project and upload to the docker registry
#

set -e

REGISTRY="openwhere"

if [ -z "$1" ]
  then
    TAG="latest"
else
    TAG=$1
fi

docker pull centos:centos7
docker build -t accumulo-docker .
docker tag -f accumulo-docker $REGISTRY/accumulo-docker:${TAG}
docker push $REGISTRY/accumulo-docker:${TAG}