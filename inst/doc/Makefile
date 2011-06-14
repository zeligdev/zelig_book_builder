# directories
DIR1 := $(shell echo `mktemp -d zelig_XXXX`)
FINAL_DIR := $(shell echo `mktemp -d zelig_XXXXXX`)
BUILD_DIR := $(shell echo `mktemp -d build_XXXXXX`)
BUILD_DIR2 = $(strip $(BUILD_DIR))
STATIC = static
#BIBDIR := $(shell echo `mktemp -d bib_XXXX`)
#DIR2 := $(shell echo `mktemp -d make_docs_XXX`)

# conf/output
CONF = order.conf
DEST = zelig.tex

# static files
BEGINNING = order/beginning
TOC = toc
END = order/ending

WD = $(shell `pwd`)

all:
	Rscript copy_and_process.R $(FINAL_DIR)
	Rscript model_sweaver.R $(DIR1) $(CONF)
	ln -f $(STATIC)/*.tex $(FINAL_DIR)/.
	ln -f $(STATIC)/*.tex $(BUILD_DIR)/.
	ln -f $(STATIC)/*.tex $(DIR1)/.
	echo -n > $(TOC)
	cat $(BEGINNING) >> $(TOC)
	echo "" >> $(TOC)
	echo "" >> $(TOC)
	echo "{Zelig Reference Manual}" >> $(TOC)
	cat $(CONF) >> $(TOC)
	cat $(END) >> $(TOC)
	perl Build_doc.pl dir=$(DIR1) ws=$(FINAL_DIR) conf=$(TOC) dest=$(DEST)	
	mv $(DEST) $(FINAL_DIR)/.
	cp .Makefile $(FINAL_DIR)/.Makefile
	make -i -C $(FINAL_DIR) -f .Makefile
	cp $(FINAL_DIR)/$(DEST) ../.
