#!/bin/sh
	echo "Eseguo il middleware"
	base_path="`readlink -f .`"	
	cd $base_path/../src/middleware/
	./middleware
