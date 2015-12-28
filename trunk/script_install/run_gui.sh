#!/bin/sh
	sleep 2s
	base_path="`readlink -f .`"	
	echo "Eseguo la gui"
	cd $base_path/../src/F1
	ant run
		
	
