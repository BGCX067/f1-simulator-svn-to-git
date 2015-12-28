#!/bin/sh

echo "Download file"

	mkdir ../download
	cd ../download/
	
	# Scarico yami4
	rm -rf yami4-gpl-1.7.0.tar.gz		
	wget http://f1-simulator.googlecode.com/files/yami4-gpl-1.7.0.tar.gz	
			
	if [ "`uname -i|grep x86_64`" = "x86_64" ]; then
		echo "Sistema 64 bit"
		
		# Scarico
		rm -rf florist-gpl-2012-src-x86_64.tgz		
		wget http://f1-simulator.googlecode.com/files/florist-gpl-2012-src-x86-64.tgz		
		rm -rf xmlada-gpl-4.3-src-x86_64.tgz		
		wget http://f1-simulator.googlecode.com/files/xmlada-gpl-4.3-src-x86-64.tgz		
		rm -rf gnatcoll-gpl-2012-src-x86_64.tgz
		wget http://f1-simulator.googlecode.com/files/gnatcoll-gpl-2012-src-x86-64.tgz
		rm -rf gnat-gpl-2012-x86_64-pc-linux-gnu-bin.tar.gz
		wget http://f1-simulator.googlecode.com/files/gnat-gpl-2012-x86_64-pc-linux-gnu-bin.tar.gz
	
	else
		echo "Sistema 32 bit"
		
		# Scarico
		rm -rf gnatcoll-gpl-2012-src.tgz
		wget http://f1-simulator.googlecode.com/files/gnatcoll-gpl-2012-src.tgz
		rm -rf xmlada-gpl-4.3-src.tgz
		wget http://f1-simulator.googlecode.com/files/xmlada-gpl-4.3-src.tgz
		rm -rf florist-gpl-2012-src.tgz
		wget http://f1-simulator.googlecode.com/files/florist-gpl-2012-src.tgz
		rm -rf gnat-gpl-2012-i686-gnu-linux-libc2.3-bin.tar.gz		
		wget http://f1-simulator.googlecode.com/files/gnat-gpl-2012-i686-gnu-linux-libc2.3-bin.tar.gz	
	fi
	
	rm -rf aws.tar.gz
	wget http://f1-simulator.googlecode.com/files/aws.tar.gz
