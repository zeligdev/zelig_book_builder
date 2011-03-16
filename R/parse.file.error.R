#' parse message string from Sweave file i/o error
#' and return the specified file
#' param e a simpleError object
#' value a character-string specifying the file that failed
parse.file.error <- function (e) {

  if (!inherits(e, 'simpleError'))
    return(NULL)

  err.string <- e$message

  file <- sub("^cannot open file '(.*)'$", "\\1", err$message, perl=TRUE)

  if (nchar(err.string) == nchar(file))
    return(NULL)

  else if (! nchar(file))
    return(NULL)

  # return
  list(
       dir  = dirname(file),
       base = basename(file)
       )
}
