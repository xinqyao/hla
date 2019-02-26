module purge
module load amber/18
#module load openmpi
module load anaconda2

gpu=0
ncore=10

export CUDA_VISIBLE_DEVICES=${gpu}
