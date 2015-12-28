../../../yami4-gpl-1.7.0/src/tools/yami4idl/src/yami4idl comunication.ydl --ada
../../../yami4-gpl-1.7.0/src/tools/yami4idl/src/yami4idl configurazioniauto_mid.ydl --ada
rm -f prova.db
gnatcoll_db2ada -dbtype=sqlite -dbname=prova.db -dbmodel=database -createdb
gnatcoll_db2ada -api=Database -dbmodel=database
gnatmake -g -Pmiddleware

