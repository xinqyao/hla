# read dG energies from complex (restraints and ddm) and ligand-only simulations
lines.restr <- readLines('restraint_run/results.txt')
lines.comp <- readLines('complex_run/results.txt')
lines.lig <- readLines('ligand_run/results.txt')

ind <- grep('TOTAL', lines.restr)
str <- strsplit(trimws(lines.restr[ind]), split='\\s+')[[1]]
#str <- str[nchar(str)>0]
dg.restr <- as.numeric(str[c(2, 5, 8, 11, 14, 17)])
names(dg.restr) <- c("TI", "TI-CUBIC", "DEXP", "IEXP", "BAR", "MBAR")
dg.restr.err <- as.numeric(str[c(4, 7, 10, 13, 16, 19)])
names(dg.restr.err) <- names(dg.restr)

ind <- grep('TOTAL', lines.comp)
str <- strsplit(trimws(lines.comp[ind]), split='\\s+')[[1]]
#str <- str[nchar(str)>0]
dg1 <- as.numeric(str[c(2, 5, 8, 11, 14, 17)])
names(dg1) <- c("TI", "TI-CUBIC", "DEXP", "IEXP", "BAR", "MBAR")
dg1.err <- as.numeric(str[c(4, 7, 10, 13, 16, 19)])
names(dg1.err) <- names(dg1)

ind <- grep('TOTAL', lines.lig)
str <- strsplit(trimws(lines.lig[ind]), split='\\s+')[[1]]
#str <- str[nchar(str)>0]
dg2 <- as.numeric(str[c(2, 5, 8, 11, 14, 17)])
names(dg2) <- c("TI", "TI-CUBIC", "DEXP", "IEXP", "BAR", "MBAR")
dg2.err <- as.numeric(str[c(4, 7, 10, 13, 16, 19)])
names(dg2.err) <- names(dg2)

kb=0.001987  # kcal/(mol*K)
T=300; V0=1660

# read reference distance and angles in the restraints between the drug and hla
lines <- readLines("RST.all")
inds <- grep("ixpk", lines)
vals <- as.numeric(sub(".*r2\\s*=\\s*(.*),\\s*r3\\s*=.*", "\\1", lines[inds]))

r0 <- vals[1]
thetaA <- vals[2] / 180 * pi
thetaB <- vals[3] / 180 * pi

Kr=20.0; KthetaA=20.0; KthetaB=20.0
KphiA=20.0; KphiB=20.0; KphiC=20.0

# penalty of restraints ()
dg3 <- kb*T*log(8*pi^2*V0*sqrt(Kr*KthetaA*KthetaB*KphiA*KphiB*KphiC)/(r0^2*sin(thetaA)*sin(thetaB)*(2*pi*kb*T)^3))

# total binding free energy (kcal/mol)
dg <- -dg1 + dg2 + dg3 + dg.restr
dg.err <- sqrt(dg1.err^2 + dg2.err^2 + dg.restr.err^2)

cat("Binding free energy:\n")
print(dg)
cat("\n")
cat("Estimated errors:\n")
print(dg.err)

