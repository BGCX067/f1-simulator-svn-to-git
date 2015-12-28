#!/bin/sh
	
	cd ~/progetto_scd/unzip/
	if [ "`uname -i|grep x86_64`" = "x86_64" ]; then
		echo "Installazione gnatcoll 64 bit"
		tar -zxvf gnatcoll-gpl-2012-src-x86-64.tgz		

	else
		echo "Installazione gnatcoll 32 bit"
		tar -zxvf gnatcoll-gpl-2012-src.tgz
	fi


	cd gnatcoll-gpl-2012-src/
	./configure --prefix=/usr/gnat
	sudo make
	sudo make install
	cd examples
	make
	make test
	
if [ "`uname -i|grep x86_64`" = "x86_64" ]; then
	rm -rf ~/progetto_scd/unzip/gnatcoll-gpl-2012-src-x86-64.tgz		
else
	rm -rf ~/progetto_scd/unzip/gnatcoll-gpl-2012-src.tgz		
fi	
