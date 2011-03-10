library(Zelig)

# open file writing handle
fi <- file("make_docsIII.conf", "w")

# 
main.commands <- readLines(system.file('doc', 'MAIN_COMMANDS', package="Zelig"))
supp.commands <- readLines(system.file('doc', 'OTHER_COMMANDS', package="Zelig"))
space <- c("", "")


writeLines(space, con=fi)

writeLines("{Main Commands}", con=fi)
writeLines(main.commands, con=fi)
writeLines(space, con=fi)


writeLines("{Supplementary Commands}", con=fi)
writeLines(supp.commands, con=fi)
writeLines(space, con=fi)


writeLines("{Zelig Models}", con=fi)
writeLines(list.zelig.models(FALSE), con=fi)
writeLines(space, con=fi)


close(fi)
