library(zelig.book.builder)


# get commandline arguments
args <- commandArgs(trailingOnly = TRUE)


# initialize variables

# file output (commandline based)
folder <- args[1]
conf <- ifelse(is.na(args[2]), "order.conf", args[2])

suppressMessages(models <- list.zelig.models())
savedwd <- getwd()
legit.models <- c()


# .....
message("** Working in directory: ", savedwd)


# Go through the list of models, and do one of:
#  * Sweave the document, then move into 'folder' (if Rnw)
#  * Copy document into folder (if TeX)
#  * Ignore (if neither)
for (mod in names(models)) {
  pkg <- models[[mod]]

  fi <- find.ref.file(mod, pkg)
  print(fi)

  if (is.null(fi)) {
    #
    # ** Skipping
    #
    message()
    message("** Skipping `", fi, "'. Cannot find Rnw/TeX file")
    message()
    next
  }

  # write file
  if (!is.null(grep('\\.Rnw$', fi))) {
    # 
    # ** Printing to ...
    #
    message()
    message("** Printing to '", fi, "'")
    message()

    # sweave the file
    suppressMessages(Sweave(fi))

    filename <- paste(mod, "tex", sep=".")

    #
    # ** Moving ...
    #
    message()
    message("** Moving '", filename, "' into '", folder, "'")
    message()

    # rename file
    success <- file.rename(filename, file.path(folder, filename))

    # adding space
    message()
  }

  else if (!is.null(grep('\\.tex$', fi))) {
    filename <- paste(mod, 'tex', sep=".")
    filename <- file.path(folder, filename)

    #
    # ** Copying ...
    #
    message()
    message("** Copying '", fi, "' into '", filename, "'")
    message()

    # copying file
    success <- file.copy(fi, filename)

    # ..
  }

  if (success)
    legit.models <- c(legit.models, mod)
}


# write to conf file
message("\n\n\n")
message("** Writing models to '", conf, "'")
writeLines(legit.models, con = conf)


message()
message('Done.')
