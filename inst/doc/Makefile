SH=sh
R=/usr/bin/R
MAKEDOCS=make_docsIII.pl
SWEAVE=run_sweave.sh
LISTMODELS=/usr/bin/Rscript
TEX_OPT_INT="-interaction nonstopmode"
SETUP_DIRS=setup_temps.sh
DEST=zelig.tex
CONF=page_order.conf


all: make_docsIII.pl make_docsIII.conf run_sweave.sh
# create necessary temporary directories
# **************************************
	$(SH) $(SETUP_DIRS)


# create a list of models
# ***********************
	$(LISTMODELS) list_zelig_models.R


# update file's timestamp (or create),
# then make it an empty file
# **************************
	touch $(CONF)
	echo -n > $(CONF)


# concatenate files
# *****************
	cat FRONT >> $(CONF)
	cat make_docsIII.conf >> $(CONF)
	cat END >> $(CONF)


# sweave the models
# *****************
	$(SH) $(SWEAVE)


# move tex files
# **************
	mv *.tex texs/.


# copy
# ****
	cp Rd2TeX/* texs/.


# build individual PDF's
# **********************
	sh run_pdflatex.sh


# assemble individual pages
# *************************
	perl make_docsIII.pl conf=$(CONF) dir=texs dest=$(DEST)


# i'm not the kind who likes to tell you
# **************************************
	pdflatex -interaction nonstopmode $(DEST)


html: 


clean:
	rm -fr texs
	rm -fr PDFs
	rm -fr vigpics
	rm *.aux
	rm *.log
	rm Rplots.pdf