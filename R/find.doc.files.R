#' find tex/Rnw files in a given package
#' param pkg a character-string specifying a package
#' return a vector of paths to files within the
#'        doc folder
find.doc.files <- function(dir = 'doc', pkg) {
  find.files(dir=dir, pkg=pkg, pattern="\\.(tex|Rnw)$")
}
