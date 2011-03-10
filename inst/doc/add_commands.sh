#!/usr/bin/sh
R=/use/bin/R

for fi in `cat MAIN_COMMANDS`
do
    new_fi=`basename ${fi} .Rd`
    ${R} CMD Rdconv
done
