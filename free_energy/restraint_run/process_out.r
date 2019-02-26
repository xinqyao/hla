lines <- readLines("recap.out")
inds <- grep("RESTRAINT\\s*=", lines)
full.restr <- as.numeric(sub(".*RESTRAINT\\s*=(.*)", "\\1", lines[inds]))

file.copy("prod.out", "bak_prod.out")
lines <- readLines("prod.out")
inds <- grep("TIME\\(PS\\)", lines)
times <- as.numeric(sub(".*TIME\\(PS\\)\\s*=\\s*(.*)\\s*TEMP.*", "\\1", lines[inds]))
inds <- inds[!duplicated(times)]
inds2 <- grep("Density\\s*=", lines)[1]
dfind <- inds2 - inds[1]

restr <- as.numeric(sub(".*RESTRAINT\\s*=(.*)", "\\1", lines[inds+4]))
ene <- as.numeric(sub(".*EPtot\\s*=(.*)", "\\1", lines[inds+1]))
#ene <- as.numeric(sub(".*EAMBER \\(non-restraint\\)\\s*=(.*)", "\\1", lines[inds+5]))
ene <- ene - restr

system("source ../../windows; echo $windows > w.tmp")
ww <- as.numeric(strsplit(readLines("w.tmp"), split="\\s+")[[1]])
unlink("w.tmp")

rst <- readLines("RST.all")
tind <- grep("rk2=", rst)[1]
curr.w <- 1.0 - (as.numeric(sub(".*rk2=(.*)\\, rk3.*", "\\1", rst[tind])) / 20.0)
curr.w <- ww[which.min(abs(ww-curr.w))]

tind <- grep("ntpr\\s*=", lines)[1]
ntpr <- as.numeric(sub(".*ntpr\\s*=\\s*([0-9]+),.*", "\\1", lines[tind]))

ind.ctrl <- grep("^NMR refinement options:", lines)

mylines <- lines[1:(ind.ctrl+2)]

mylines <- c(mylines, c("Free energy options:", 
"     icfe    =       1, ifsc    =       0, klambda =       1",
paste("     clambda =", sprintf("%8.4f", curr.w), ", scalpha =  0.5000, scbeta  = 12.0000", sep=""),
"     sceeorder =       2",
"     dynlmb =  0.0000 logdvdl =       0",
"",
"FEP MBAR options:",
paste("     ifmbar  =       1,  bar_intervall =", sprintf("%9d", ntpr), sep=""),
paste("     mbar_states =", sprintf("%8d", length(ww)), sep="")) )

j <- ind.ctrl + 3

tind <- grep("^   3.  ATOMIC", lines) - 2
mylines <- c(mylines, lines[j:tind])

mylines <- c(mylines, c(
"    MBAR - lambda values considered:",
paste(sprintf("%8d", length(ww)), " total: ", paste(sprintf("%7.4f", ww), collapse=""), sep=""),
"    Extra energies will be computed      XX times.") )

j <- tind + 1
for(i in 1:length(inds)) {
  mylines <- c(mylines, lines[j:(inds[i]-1)])
  mylines <- c(mylines, "MBAR Energy analysis:")
  mylines <- c(mylines, paste("Energy at ", sprintf("%6.4f", ww), " =", sprintf("%13.4f", ene[i] + full.restr[i]*(1-ww)), sep=""))
  mylines <- c(mylines, " ------------------------------------------------------------------------------\n\n")
  mylines <- c(mylines, lines[(inds[i]):(inds[i]+dfind)])
  mylines <- c(mylines, paste(" DV/DL  =", sprintf("%15.4f", -full.restr[i]), sep=""))
  mylines <- c(mylines, " ------------------------------------------------------------------------------")
  j <- inds[i] + dfind + 1 
}
mylines <- c(mylines, lines[j:length(lines)])

cat(mylines, sep="\n", file="prod.out")

