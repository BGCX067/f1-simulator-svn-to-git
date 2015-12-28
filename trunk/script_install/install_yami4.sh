#!/bin/sh

echo "Installazione yami4"

cd ~/progetto_scd/unzip/
tar -zxvf  yami4-gpl-1.7.0.tar.gz
	
# Correzione bug yami trovati da Michele
$base_path/correzione_yami_bug.sh
				
cd yami4-gpl-1.7.0/src/
cd core
make
cd ../cpp/
make
cd ../ada/
gnatmake -Pyami
cd ../java/
ant
cd ..

echo "Installazione compilatore yami4idl"
cd tools/yami4idl/src/
gnatmake yami4idl.adb

rm -rf ~/progetto_scd/unzip/yami4-gpl-1.7.0.tar.gz

