#!/usr/bin/sh
Rscript=/usr/bin/Rscript

# match first instance of "Header" or "HeaderA"
MATCH="\\HeaderA\?{\(.*\?\)}{\(.*\?\)}{\(.*\?\)}"

# convert into a section, title, and label
REPLACE="\\section{{\\\\tt \1}: \2}\\\\label{ss:\3}"



#
if [ ! -d Rd2TeX ]
then
    mkdir Rd2TeX
fi

${Rscript} extract_Rd_files.R
sed -i -e  "s/${MATCH}/${REPLACE}/" Rd2TeX/*

cp Rd2TeX/* texs/.
