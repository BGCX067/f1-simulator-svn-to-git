#!/bin/sh

echo "Script installazione per progetto SCD"
echo "v2.3 17/11/2013"

# Rendo eseguibili gli altri script
chmod +x aggiorna_bashrc.sh
chmod +x install_aws.sh
chmod +x correzione_yami_bug.sh
chmod +x install_yami4.sh
chmod +x download.sh
chmod +x install_gnatcoll.sh
chmod +x install_xmlada.sh
chmod +x install_florist.sh
chmod +x prepara_file.sh
chmod +x install_gnat.sh
chmod +x run_middleware.sh
chmod +x run_race.sh
chmod +x run_gui.sh
chmod +x run_browser.sh
chmod +x compile.sh

clear


base_path="`readlink -f .`"

echo ""
echo "  MMM v2.3 MMM    MMMMMMMD    MMMMMMMMMMM   MMMMMMM    MMMMMM8 MMMM    8MMMM MMMMI           MMMMM                    MMMM "
echo "  MMMMMMMMMMMM  MMMMMMMMMMMM  MMMMMMMMMMMMM MMMMMMM    MMMMMM8 MMMM    8MMMM MMMMI           MMMMMM                  MMMMM "
echo "  MMMMMMMMMMMM MMMMMN  MMMMMM MMMMI   MMMMM MMMMMMMM  MMMMMMM8 MMMM    8MMMM MMMMI          MMMMMMM7              MMMMMMMM "
echo "  MMMMM        MMMM     IMMMM MMMMI    MMMM MMMMMMMM  MMMMMMM8 MMMM    8MMMM MMMMI         :MMMMMMMM              MMMMMMMM "
echo "  MMMMMMMMMMMM MMMM      MMMM MMMMMMMMMMMM  MMMMNMMMDNMMMMMMM8 MMMM    8MMMM MMMMI         MMMM DMMMN                MMMMM "
echo "  MMMMMMMMMMMM MMMM      MMMM MMMMMMMMMMMM  MMMMN MMMMMM MMMM8 MMMM    8MMMM MMMMI        OMMMM  MMMM                MMMMM "
echo "  MMMMM        MMMMD    MMMMM MMMMI   MMMMM MMMMN MMMMMM MMMM8 MMMM    MMMMM MMMM?        MMMMMMMMMMMM               MMMMM "
echo "  MMMMM        MMMMMMMMMMMMM  MMMMI    MMMM MMMMN MMMMMM MMMM8 MMMMMMMMMMMMM MMMMMMMMMMM MMMMMMMMMMMMM               MMMMM "
echo "  MMMMM          MMMMMMMMMM   MMMMI    MMMMMMMMMN  MMMM  MMMM8  MMMMMMMMMMM  MMMMMMMMMMM MMMM     MMMMM              MMMMM "
echo "  MMMMN            MMMMMD     MMMMI    NMMMMMMMMN  MMMM  MMMMD    MMMMMM8    MMMMMMMMMMMMMMMM      MMMM7             MMMMM "
echo ""
echo "                                                                            (by M. Tonon, A. Gonella, D. Vettore, D. Benna)"
echo ""
echo ""
echo ""
echo "Scegli (1) per il checkout"
echo "Scegli (2) per svn up"
echo "Scegli (3) per svn up e compilare il progetto"
echo "Scegli (4) per compilare il progetto"
echo #"Scegli (-2) per uccidere il processo middleware"
echo ""
echo "---------- COMANDI DI ESECUZIONE ----------"
echo ""
echo "Scegli (5) per eseguire il middleware"
echo "Scegli (6) per eseguire la gara"
echo "Scegli (7) per eseguire la gui"
echo ""
echo "Scegli (0) per eseguire tutto"
echo ""
echo ""

echo -n "Inserisci la scelta > "
read text
echo "Hai scelto: $text"

#if [ "$text" -eq 1 ]; then
	# Download dei file dal repository
#	$base_path/download.sh
#fi

#if [ "$text" -eq 2 ]; then


#	echo "Preparo i file da installare"
#	$base_path/prepara_file.sh >  $base_path/log/prepara_file.log

	##########################################################################

	# Installazione gnat
#	echo "Installo gnat"
#	$base_path/install_gnat.sh >  $base_path/log/gnat.log
	
	# Modifico file di bashrc solo se è necessario
#	echo "Aggiorno la bashrc"
#	$base_path/aggiorna_bashrc.sh >  $base_path/log/aggiorna_bashrc.log
	

	##########################################################################

	# Installazione florist
#	echo "Installo florist"
#	$base_path/install_florist.sh >  $base_path/log/florist.log

	##########################################################################

	# Installazione xml ada
#	echo "Installo xmlada"
#	$base_path/install_xmlada.sh >  $base_path/log/xmlada.log

	##########################################################################

	# Installazione gnat coll
#	echo "Installo gnatcoll"
#	$base_path/install_gnatcoll.sh >  $base_path/log/gnatcoll.log

	##########################################################################
	
	# Installazione aws
#	echo "Installo aws"
#	$base_path/install_aws.sh >  $base_path/log/aws.log

	##########################################################################
	
	# Installazione yami4
#	echo "Installo yami4"	
#	$base_path/install_yami4.sh >  $base_path/log/yami4.log
#	echo "Fine installazione!"			
#fi

if [ "$text" -eq 1 ]; then
	echo "Scarico il progetto"
	cd $base_path
 	#svn checkout https://f1-simulator.googlecode.com/svn/ f1-simulator --username diego.benna@gmail.com
 	svn checkout https://f1-simulator.googlecode.com/svn/trunk f1-simulator --username diego.benna@gmail.com
fi

if [ "$text" -eq 4 ]; then
	
	$base_path/compile.sh
	echo "Compilo il middleware e il progetto"


fi

if [ "$text" -eq 5 ]; then
	$base_path/run_middleware.sh
	cd $base_path
fi

if [ "$text" -eq 6 ]; then
	$base_path/run_race.sh
	cd $base_path
fi

if [ "$text" -eq 7 ]; then
	$base_path/run_gui.sh
	cd $base_path
fi

if [ "$text" -eq 2 ]; then
	base_path="`readlink -f .`"	
	cd ..
	svn up
fi

if [ "$text" -eq 3 ]; then
	base_path="`readlink -f .`"	
	cd ..
	svn up
	cd script_install/
	./compile.sh
	cd $base_path
fi

if [ "$text" -eq "-2" ]; then
	killall middleware
	cd $base_path
fi

if [ "$text" -eq 0 ]; then
#	gnome-terminal --tab -e "tail -f somefile" --tab -e "$base_path/run_middleware.sh"
#	sleep 1s
#	gnome-terminal --tab -e "tail -f somefile" --tab -e "$base_path/run_race.sh"
#	sleep 1s
#	gnome-terminal --tab -e "tail -f somefile" --tab -e "$base_path/run_gui.sh"
	
	gnome-terminal --tab -e "$base_path/run_middleware.sh" --tab -e "$base_path/run_race.sh" --tab -e "$base_path/run_gui.sh" --tab -e "$base_path/run_browser.sh"
fi


