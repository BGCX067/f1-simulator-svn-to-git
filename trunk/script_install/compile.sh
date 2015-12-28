#!/bin/sh
	base_path="`readlink -f .`"
	cd $base_path/../src/middleware/
	./build.sh
		
	cd $base_path/../
	gnatmake -Pf1
	
	cd $base_path
	
	cd $base_path/../src/F1
	ant
