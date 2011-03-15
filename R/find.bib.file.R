#' find bib files in a given package
#' param pkg a character-string specifying a package
#' return a vector of paths to bib files within the
#'        doc folder
find.bib.files <- function(dir = 'doc', pkg) {
  # get specified directory
  doc.dir <- system.file(dir, package=pkg)

  # search for all bib files
  files <- dir(doc.dir, '\\.bib$')

  # make into absolute paths, and return
  file.path(doc.dir, files)
}
