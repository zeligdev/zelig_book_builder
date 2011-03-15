# directories
DIR1 := $(shell echo `mktemp -d tex_XXXX`)
BIBDIR := $(shell echo `mktemp -d bib_XXXX`)
#DIR2 := $(shell echo `mktemp -d make_docs_XXX`)

# conf/output
CONF = order.conf
DEST = zelig.tex

# static files
BEGINNING = beginning
TOC = toc
END = ending

all:
	Rscript model_sweaver.R $(DIR1) $(CONF)
	echo -n >> $(TOC)
	cat $(BEGINNING) >> $(TOC)
	echo "\\n\\n{Zelig Reference Manual}" >> $(TOC)
	cat $(CONF) >> $(TOC)
	cat $(END) >> $(TOC)
	perl build_doc.pl dir=$(DIR1) conf=$(CONF) dest=$(DEST)	
