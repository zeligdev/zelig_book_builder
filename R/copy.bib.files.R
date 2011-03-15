#' copy bib files from a specified directory
#' to another
#' param pkg a character-string specifying a package name
#'       if null - local paths are used
#' param to a character-string specifying the destination directory
#' param dir a character-string specifying the source directory
#' value a logical vector specifying all the results
copy.bib.files <- function(pkg = NULL, to ='.', dir="doc") {

  results <- c()

  bibs <- find.bib.files(dir = dir, pkg = pkg)

  for (source in bibs) {
    # construct destination file name
    dest <- file.path(to, basename(source))
    
    # attempt to copy file, then save result
    results[basename(source)] <- file.copy(source, dest)
  }

  # return
  results
}
