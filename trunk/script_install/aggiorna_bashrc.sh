#!/bin/sh
	
	if [ "`grep -e "/usr/gnat/bin:" ~/.bashrc`" ];then
		echo "Non è necessario fare modifiche al file"
	 else	
		echo "
		PATH=/usr/gnat/bin:$PATH
		export PATH

		GPR_PROJECT_PATH=/usr/gnat/lib/gnat
		export GPR_PROJECT_PATH

		ADA_PROJECT_PATH=/usr/gnat/lib/gnat
		export ADA_PROJECT_PATH
		" >> ~/.bashrc
	fi


	gnatmake --version
