#' find reference file - Rnw or tex in inst/doc
#' param model a character-string specifying the model name
#' param package a character-string specifying the package name
#' return a character-string specifying the absolute path to the file
#'        or NULL on a failure
find.ref.file <- function(model, package) {
  rnw.file <- system.file('doc', paste(model, 'Rnw', sep='.'), package=package)
  tex.file <- system.file('doc', paste(model, 'tex', sep='.'), package=package)

  if (file.exists(rnw.file)) {
    rnw.file
  }
  else if (file.exists(tex.file)) {
    tex.file
  }
  else {
    NULL
  }
}

