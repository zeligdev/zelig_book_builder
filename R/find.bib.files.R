#' find bib files in a given package
#' param pkg a character-string specifying a package
#' return a vector of paths to bib files within the
#'        doc folder
find.bib.files <- function(dir = 'doc', pkg) {
  find.files(dir=dir, pkg=pkg, pattern="\\.bib$")
}
