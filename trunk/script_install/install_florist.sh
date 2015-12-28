#!/bin/sh
	
cd ~/progetto_scd/unzip/
if [ "`uname -i|grep x86_64`" = "x86_64" ]; then
	echo "Installazione floris 64 bit"
	tar -zxvf florist-gpl-2012-src-x86-64.tgz
else
	echo "Installazione floris 32 bit"
	tar -zxvf florist-gpl-2012-src.tgz	
fi


cd florist-gpl-2012-src/
./configure --prefix=/usr/gnat
make -j 4
make install

if [ "`uname -i|grep x86_64`" = "x86_64" ]; then
	rm -rf ~/progetto_scd/unzip/florist-gpl-2012-src-x86-64.tgz		
else
	rm -rf ~/progetto_scd/unzip/florist-gpl-2012-src.tgz		
fi	
