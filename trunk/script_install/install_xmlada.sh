#!/bin/sh
	
cd ~/progetto_scd/unzip/
if [ "`uname -i|grep x86_64`" = "x86_64" ]; then
	echo "Installazione xmlada 64 bit"
	tar -zxvf xmlada-gpl-4.3-src-x86-64.tgz 

else
	echo "Installazione xmlada 32 bit"
	tar -zxvf xmlada-gpl-4.3-src.tgz 		
fi


cd xmlada-4.3w-src/
./configure --prefix=/usr/gnat
make
sudo make install
make test

if [ "`uname -i|grep x86_64`" = "x86_64" ]; then
	rm -rf ~/progetto_scd/unzip/xmlada-gpl-4.3-src-x86-64.tgz
	
	# Correzione nel caso non ci sia sistema Ubuntu
	export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu			
else
	rm -rf ~/progetto_scd/unzip/xmlada-gpl-4.3-src.tgz
	export LIBRARY_PATH=/usr/lib/i386-linux-gnu
fi
