#!/bin/sh
	
	cd ../download
	echo "Creo cartella principale"
	
	rm -rf ~/progetto_scd 
	mkdir ~/progetto_scd
	mkdir ~/progetto_scd/unzip

	# Sposto i file
	cp yami4-gpl-1.7.0.tar.gz ~/progetto_scd/unzip/
	cp aws.tar.gz ~/progetto_scd/unzip/	
		
	if [ "`uname -i|grep x86_64`" = "x86_64" ]; then
		echo "Sistema 64 bit"
		
		# Sposto i file
		cp -rf gnat-gpl-2012-x86_64-pc-linux-gnu-bin.tar.gz ~/progetto_scd/unzip/
		#cp -rf aws-gpl-2.11.0-src-x86-64.tgz ~/progetto_scd/unzip/
		cp -rf gnatcoll-gpl-2012-src-x86-64.tgz ~/progetto_scd/unzip/
		cp -rf xmlada-gpl-4.3-src-x86-64.tgz ~/progetto_scd/unzip/
		cp -rf florist-gpl-2012-src-x86-64.tgz ~/progetto_scd/unzip/
			
	else
		echo "Sistema 32 bit"
		
		# Sposto i file
		cp -rf gnat-gpl-2012-i686-gnu-linux-libc2.3-bin.tar.gz ~/progetto_scd/unzip/
		#cp -rf aws-gpl-2.11.0-src.tgz ~/progetto_scd/unzip/
		cp -rf gnatcoll-gpl-2012-src.tgz ~/progetto_scd/unzip/
		cp -rf xmlada-gpl-4.3-src.tgz ~/progetto_scd/unzip/
		cp -rf florist-gpl-2012-src.tgz ~/progetto_scd/unzip/
	fi
	sudo chmod -R 777 ~/progetto_scd/
