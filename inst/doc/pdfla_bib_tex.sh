#!/bin/tcsh
# Script to run pdflatex twice, then
pdflatex $1
pdflatex $1
bibtex $1
pdflatex $1
