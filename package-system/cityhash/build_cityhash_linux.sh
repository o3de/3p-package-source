#!/bin/bash


echo "Configuring cityhash"
cd src

INSTALL_DIR=/data/workspace/build

if [ "$(uname -m)"="aarch64" ]
then
    echo "Configuring cityhash for ARM64"
    ./configure --build=arm --prefix=$INSTALL_DIR
else 
    echo "Configuring cityhash for x86_64"
    ./configure --prefix=$INSTALL_DIR
fi

if [ $? -ne 0 ]
then
    echo "Failed configuring cityhash"
    exit 1
fi

make all
if [ $? -ne 0 ]
then
    echo "Failed building cityhash"
    exit 1
fi

make check
if [ $? -ne 0 ]
then
    echo "Failed testing cityhash"
    exit 1
fi

make install
if [ $? -ne 0 ]
then
    echo "Failed installing cityhash"
    exit 1
fi

echo "cityhash built successfully"
exit 0
