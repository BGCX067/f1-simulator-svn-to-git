#!/bin/sh
# Documentazione aws http://docs.adacore.com/aws-docs/aws.html#WebSockets

echo "Installazione aws"
cd ../download/

cd ~/progetto_scd/unzip/
sudo tar -zxvf  ~/progetto_scd/unzip/aws.tar.gz 
sudo chmod -R 777 aws
cd aws/
sudo make setup build install

# test di aws
cd demos
cd hello_world/
gnat make -P hello_world
./hello_world 

rm -rf ~/progetto_scd/unzip/aws.tar.gz		
