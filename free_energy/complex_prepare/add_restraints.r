library(bio3d)

pdb <- read.pdb('complex_nowat.pdb')

inds.lig <- atom.select(pdb, "ligand", elety=c('C2', 'C5', 'N4'))
bs <- binding.site(pdb, a.inds=atom.select(pdb, 'calpha'), b.inds=as.select(inds.lig$atom[2]), cutoff=8)
inds.pro <- atom.select(pdb, 'protein', resno=bs$resno[1], elety=c('N', 'CA', 'C'))

# find hla residue that make minmal angles (better between 60~120 degree)
theta1 <- NULL; theta2 <- NULL
for(i in 1:length(bs$resno)) {
  inds.pro <- atom.select(pdb, 'protein', resno=bs$resno[i], elety=c('N', 'CA', 'C'))
  i <- inds.pro$atom[2]; j<- inds.pro$atom[1]; k<- inds.lig$atom[2]
  theta1 <- c(theta1, round(angle.xyz(pdb$xyz[atom2xyz(c(i,j,k))]), 1))
  i <- inds.pro$atom[1]; j<- inds.lig$atom[2]; k<- inds.lig$atom[1]
  theta2 <- c(theta2, round(angle.xyz(pdb$xyz[atom2xyz(c(i,j,k))]), 1))
#  if(theta1 >=60 && theta1 <=120 && theta2 >=60 && theta2 <=120) break
}
inds <- which(theta1 >=60 & theta1 <=120 & theta2 >=60 & theta2 <=120)
if(length(inds)==0) 
   inds <- which(theta1 >=50 & theta1 <=130 & theta2 >=50 & theta2 <=130)
if(length(inds)==0)
   inds <- which(theta1 >=40 & theta1 <=140 & theta2 >=40 & theta2 <=140)
if(length(inds)==0)
   inds <- which(theta1 >=30 & theta1 <=150 & theta2 >=30 & theta2 <=150)
if(length(inds)==0)
  stop(paste('Cannot find suitable protein residue to restraint ligand.', 
                theta1, theta2, sep='\n'))
inds <- inds[1]
inds.pro <- atom.select(pdb, 'protein', resno=bs$resno[inds], elety=c('N', 'CA', 'C'))
theta1 <- theta1[inds]
theta2 <- theta2[inds]
###########

i <- inds.pro$atom[1]; j <- inds.lig$atom[2]
dd <- dist.xyz(pdb$xyz[atom2xyz(i)], pdb$xyz[atom2xyz(j)])

cat("# distance
 &rst
  ixpk= 0, nxpk= 0, iat= ", i, ",", j, ", r1= 0.0, r2= ", round(dd, 3), ", ", "r3= ", round(dd, 3), ", r4= 999.,
      rk2=20.0, rk3=20.0, ir6=1, ialtd=0,
 &end

", sep="", file="RST.all", append=FALSE)


i <- inds.pro$atom[2]; j<- inds.pro$atom[1]; k<- inds.lig$atom[2]
theta1 <- round(angle.xyz(pdb$xyz[atom2xyz(c(i,j,k))]), 1)
cat("# angles
 &rst
  ixpk= 0, nxpk= 0, iat= ", i, ",", j, ",", k, ", r1= 0.0, r2= ", theta1, ", r3= ", theta1, ", r4= 180,
      rk2=20.0, rk3=20.0, ir6=1, ialtd=0,
 &end
", sep="", file="RST.all", append=TRUE)

i <- inds.pro$atom[1]; j<- inds.lig$atom[2]; k<- inds.lig$atom[1]
theta2 <- round(angle.xyz(pdb$xyz[atom2xyz(c(i,j,k))]), 1)
cat("
 &rst
  ixpk= 0, nxpk= 0, iat= ", i, ",", j, ",", k, ", r1= 0.0, r2= ", theta2, ", r3= ", theta2, ", r4= 180,
      rk2=20.0, rk3=20.0, ir6=1, ialtd=0,
 &end

", sep="", file="RST.all", append=TRUE)


i <- inds.pro$atom[3]; j<- inds.pro$atom[2]; k<- inds.pro$atom[1]; l <- inds.lig$atom[2]
dih1 <- round(torsion.xyz(pdb$xyz[atom2xyz(c(i,j,k,l))]), 1)
cat("# dihedrals
 &rst
  ixpk= 0, nxpk= 0, iat= ", i, ",", j, ",", k, ",", l, ", r1= ", dih1-180, ", r2= ", dih1, ", r3= ", dih1, ", r4= ", dih1+180, ",
      rk2=20.0, rk3=20.0, ir6=1, ialtd=0,
 &end
", sep="", file="RST.all", append=TRUE)

i <- inds.pro$atom[2]; j<- inds.pro$atom[1]; k<- inds.lig$atom[2]; l <- inds.lig$atom[1]
dih2 <- round(torsion.xyz(pdb$xyz[atom2xyz(c(i,j,k,l))]), 1)
cat("
 &rst
  ixpk= 0, nxpk= 0, iat= ", i, ",", j, ",", k, ",", l, ", r1= ", dih2-180, ", r2= ", dih2, ", r3= ", dih2, ", r4= ", dih2+180, ",
      rk2=20.0, rk3=20.0, ir6=1, ialtd=0,
 &end
", sep="", file="RST.all", append=TRUE)

i <- inds.pro$atom[1]; j<- inds.lig$atom[2]; k<- inds.lig$atom[1]; l <- inds.lig$atom[3]
dih3 <- round(torsion.xyz(pdb$xyz[atom2xyz(c(i,j,k,l))]), 1)
cat("
 &rst
  ixpk= 0, nxpk= 0, iat= ", i, ",", j, ",", k, ",", l, ", r1= ", dih3-180, ", r2= ", dih3, ", r3= ", dih3, ", r4= ", dih3+180, ",
      rk2=20.0, rk3=20.0, ir6=1, ialtd=0,
 &end
", sep="", file="RST.all", append=TRUE)
