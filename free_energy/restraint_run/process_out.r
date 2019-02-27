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
tind <- grep("ntave\\s*=", lines)[1]
ntave <- as.numeric(sub(".*ntave\\s*=\\s*([0-9]+),.*", "\\1", lines[tind]))

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

avg.dvdl <- NULL
dvdl <- 0.0
j <- tind + 1
for(i in 1:length(inds)) {
  mylines <- c(mylines, lines[j:(inds[i]-1)])
  mylines <- c(mylines, "MBAR Energy analysis:")
  mylines <- c(mylines, paste("Energy at ", sprintf("%6.4f", ww), " =", sprintf("%13.4f", ene[i] + full.restr[i]*(1-ww)), sep=""))
  mylines <- c(mylines, " ------------------------------------------------------------------------------\n\n")
  mylines <- c(mylines, lines[(inds[i]):(inds[i]+dfind)])
  mylines <- c(mylines, paste(" DV/DL  =", sprintf("%15.4f", -full.restr[i]), sep=""))
  mylines <- c(mylines, " ------------------------------------------------------------------------------")
  dvdl <- dvdl - full.restr[i]
  if((ntpr * i) %% ntave == 0) {
     avg.dvdl <- c(avg.dvdl, dvdl / (ntave/ntpr))
     dvdl <- 0.0
  }
  j <- inds[i] + dfind + 1 
}
mylines <- c(mylines, lines[j:length(lines)])

### add average DV/DL
inds <- grep("R M S  F L U C T U A T I O N S", mylines)
inds2 <- grep(" -----", mylines)
inds2 <- inds2[inds2>inds[1]]
inds2 <- inds2[1:(which(inds2>inds[length(inds)])[1])]
dm <- as.matrix(dist(c(inds, inds2)))
dm <- dm[1:length(inds), (length(inds)+1):ncol(dm)]
inds2 <- inds2[apply(dm, 1, which.min)]

mylines2 <- NULL
j <- 1
for(i in 1:length(inds)) {
   tmp <- mylines[inds[i]+3]
   mylines2 <- c(mylines2, mylines[j:inds2[i]])
   mylines2 <- c(mylines2, c(
"",
"",
paste("      DV/DL, AVERAGES OVER ", ntave, " STEPS", sep=""),
"",
"",
tmp,
" Etot   =         0.0000  EKtot   =         0.0000  EPtot      =         0.0000",
" BOND   =         0.0000  ANGLE   =         0.0000  DIHED      =         0.0000",
" 1-4 NB =         0.0000  1-4 EEL =         0.0000  VDWAALS    =         0.0000",
paste(" EELEC  =         0.0000  EHBOND  =         0.0000  RESTRAINT  =", sprintf("%15.4f", avg.dvdl[i]), sep=""),
" EKCMT  =         0.0000  VIRIAL  =         0.0000  VOLUME     =         0.0000",
"                                                    Density    =         0.0000",
paste(" DV/DL  =", sprintf("%15.4f", avg.dvdl[i]), sep=""),
" ------------------------------------------------------------------------------"))
   j <- inds2[i] + 1
}
mylines2 <- c(mylines2, mylines[j:length(mylines)])

cat(mylines2, sep="\n", file="prod.out")

