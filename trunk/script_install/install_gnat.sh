#!/bin/sh
	
	# Correzione Ubuntu 64bit
	if [ "`uname -i|grep x86_64`" = "x86_64" ]; then
		sudo apt-get install libc6-dev-i386
	fi	
	
	cd ~/progetto_scd/unzip/
	if [ "`uname -i|grep x86_64`" = "x86_64" ]; then
		echo "Installazione gnat 64 bit"
		tar -zxvf gnat-gpl-2012-x86_64-pc-linux-gnu-bin.tar.gz
		cd gnat-2012-x86_64-pc-linux-gnu-bin/

	else
		echo "Installazione gnat 32 bit"
		tar -zxvf gnat-gpl-2012-i686-gnu-linux-libc2.3-bin.tar.gz 
		cd gnat-2012-i686-gnu-linux-libc2.3-bin/

	fi

clear
echo "Per installare GNAT sarà necessario avere permessi di root"
echo "Procedere (Yy/Nn)?"

echo -n "Inserisci la scelta > "
read text

#if [ "$text"  -eq "y" || "$text" -eq "Y" ]; then	
	sudo ./doinstall
	if [ "`uname -i|grep x86_64`" = "x86_64" ]; then
		rm -rf ~/progetto_scd/unzip/gnat-gpl-2012-x86_64-pc-linux-gnu-bin.tar.gz		
	else
		rm -rf ~/progetto_scd/unzip/gnat-gpl-2012-i686-gnu-linux-libc2.3-bin.tar.gz		
	fi	
#else
#	exit 0
#fi
	
	
