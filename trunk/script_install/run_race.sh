#!/bin/sh
	sleep 1s
	base_path="`readlink -f .`"	
	echo "Eseguo il progetto"
	cd $base_path/../
	./obj/gara
		
	
