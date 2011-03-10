library(Zelig)

# @model: name of the zelig model
# @package: name of the zelig package
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


# initialize variables
folder <- "temporary.folder"
suppressMessages(models <- list.zelig.models())
savedwd <- getwd()

message("working in directory: ", savedwd)

## if (file.exists(folder))
##   stop()

#dir.create(folder)


# setup working environment
#setwd(folder)


for (mod in names(models)) {
  pkg <- models[[mod]]

  fi <- find.ref.file(mod, pkg)

  if (is.null(fi)) {
    #xwarning(mod, " is not found. skipping.")
    next
  }

  # write file
  if (!is.null(grep('\\.Rnw', fi))) {
    message('printing to "', fi, '"')
    suppressMessages(Sweave(fi))
    message()
    message()
  }
}


#warnings()
#setwd(savedwd)
