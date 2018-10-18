#!/bin/bash -l

export DIST_PATH="/home/dev/host/dist"

cp -r ~/host/dist $PWD/..
if [ ! -f Dockerfile.app ];then
  echo "Not in project root directory"
  exit 1
fi

if [ -d $DIST_PATH ];then
  echo "Copy client assets from $DIST_PATH"
  cp -R $DIST_PATH dist
fi

echo "Build app-img"
tagname="app-img"
version=`cat /home/dev/Development/workships/VERSION`
tagname="${tagname}:${version}"

docker build -t $tagname -f Dockerfile.app .
