library(bio3d)
pro <- read.pdb('sys_nowat.pdb')
ref <- read.pdb('ref.pdb')
pro$atom$chain <- chain.pdb(pro)
pro <- trim(pro, chain='A')

# will keep the peptide presenting domain only
aa1 <- pdbseq(ref)
aa2 <- pdbseq(pro)
aln <- seqaln(seqbind(aa1, aa2), id=c('ref.pdb', 'sys_nowat.pdb'))
pdbs <- read.fasta.pdb(aln)
ind <- which(pdbs$resno[1, ] %in% 181)
resno <- pdbs$resno[2, ind]
pro <- trim(pro, "noh", resno=1:resno)
write.pdb(pro, file='sys_nowat_cut.pdb')

lig <- read.pdb2('ligand_vina.pdb')
lig$atom$resno <- rep(1, nrow(lig$atom))
#write.pdb(lig, resid=rep("ABC", nrow(lig$atom)), chain="A", file="ligand_vina1.pdb")
write.pdb(lig, file="ligand_vina1.pdb")

