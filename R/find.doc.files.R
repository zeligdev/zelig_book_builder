#' find tex/Rnw files in a given package
#' param pkg a character-string specifying a package
#' return a vector of paths to files within the
#'        doc folder
find.doc.files <- function(dir = 'doc', pkg) {
  # get specified directory
  doc.dir <- system.file(dir, package=pkg)

  # search for all bib files
  files <- dir(doc.dir, '\\.(tex|Rnw)$')

  # make into absolute paths, and return
  file.path(doc.dir, files)
}

