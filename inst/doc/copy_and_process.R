library(zelig.book.builder)

# get commandline arguments
args <- commandArgs(trailingOnly = TRUE)

folder <- args[1]
conf <- ifelse(is.na(args[2]), "order.conf", args[2])

# get models and packages
models <- list.zelig.models()
packages <- list.zelig.dependent.packages()
packages <- c("Zelig", packages)

# copy over bib/tex/Rnw files from each Zelig dependent package
for (pkg in packages) {
  copy.bib.files(pkg = pkg, to = folder)
  copy.doc.files(pkg = pkg, to = folder)
  copy.sty.files(pkg = pkg, to = folder)
}
