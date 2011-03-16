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


# sweave files
setwd(folder)
sweave.files <- dir(pattern='\\.Rnw$')

#
for (fi in sweave.files) {

  # attempt to Sweave, then parse error
  err <- tryCatch(Sweave(fi), error = function (e) e)
  err <- parse.file.error(err)


  # if it actually is a file i/o error,
  # try to make the directory
  if (!is.null(err)) {

    message()
    message("** Catching error, and attempting to resolve")
    
    # create directory
    result <- dir.create(err$dir, recursive=TRUE)

    # message or sweave
    if (!result)
      message("-- FAILED TO MAKE DIRECTORY: ", err$dir)
    else
      Sweave(fi)

    message()
  }
}
