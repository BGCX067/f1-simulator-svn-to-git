#!/bin/sh

# Correzione dei bug di yami4

echo "Correzione bug di yami trovati da Michele"

cd ~/progetto_scd/unzip/yami4-gpl-1.7.0/src/tools/yami4idl/src/

cp idl-structures-ada_generator.adb idl-structures-ada_generator.adb.bk

sed '356 c\Put_Line (                           File, "      P_Y4.Set_Long_Float (""" &' idl-structures-ada_generator.adb.bk  > idl-structures-ada_generator.adb

cp idl-structures-ada_generator.adb idl-structures-ada_generator.adb.bk2

sed '492 c\"                           := P_Y4.Get_Long_Float (""" & YAMI4_Field_Name (Field_Name) & """);");' idl-structures-ada_generator.adb.bk2  > idl-structures-ada_generator.adb
