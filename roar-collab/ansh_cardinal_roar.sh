#!/bin/bash

if [ $# -lt 4 ] || [ $# -gt 6 ]; then
  echo "usage:$0 <moose file, without \.i> <no. of nodes> <time> [<nekrs case=cardinal input>] [<gpus/node=2>] [<min mem=64 GB>]"
  exit 0
fi

case=${1}
nnodes=$2
time=$3
nrscase=${4-:$case}
ngpus_per_node=${5:-2} # in case you want to run in serial
#ncpus_per_node=32 # 48, don't saturate, in case you want to run on cpus
mem="${6:-64G}" #min memory reqd, the max is 380G per node, system default for mem param - 4GB

ntasks=$((nnodes*ngpus_per_node))
#n_cpu_tasks=$((nnodes*ncpus_per_node)) # could add an additional param to control this, but meh

CMDFILE=$1.slurm

export CARDINAL_DIR=$(realpath -P /storage/home/afc6440/work/cardinal)
bin=${CARDINAL_DIR}/cardinal-opt

echo "#!/bin/bash" > $CMDFILE
echo "#SBATCH --job-name=$case" >> $CMDFILE
echo "#SBATCH --time=$time" >> $CMDFILE
echo "#SBATCH --nodes=$nnodes" >> $CMDFILE
echo "#SBATCH --ntasks-per-node=$ngpus_per_node" >> $CMDFILE
echo "#SBATCH --gpus-per-task=1" >> $CMDFILE
echo "#SBATCH --gpu-bind=closest" >> $CMDFILE
echo "#SBATCH --mem=$mem" >> $CMDFILE
echo "#SBATCH --exclusive" >> $CMDFILE
echo "#SBATCH --account=ebm5351_b_gpu" >> $CMDFILE
echo "#SBATCH --partition=sla-prio" >> $CMDFILE
echo "" >> $CMDFILE


echo "export CARDINAL_DIR=${CARDINAL_DIR}" >> $CMDFILE
echo "export NEKRS_HOME=$CARDINAL_DIR/install" >> $CMDFILE
echo "module purge" >> $CMDFILE
echo "module load anaconda/2023.09" >> $CMDFILE
echo "conda activate cardinal" >> $CMDFILE
echo "module load openmpi/4.1.1-pmi2" >> $CMDFILE
echo "" >> $CMDFILE
echo "module load gcc/9.1.0" >> $CMDFILE
echo "export GCC_DIR=/storage/icds/RISE/sw8/gcc/gcc-9.1.0/bin/" >> $CMDFILE
echo "export PATH=\$GCC_DIR:\$PATH " >> $CMDFILE
echo "export OMPI_CC=\$GCC_DIR/gcc" >> $CMDFILE
echo "export OMPI_CXX=\$GCC_DIR/g++" >> $CMDFILE
echo "export OMPI_FC=\$GCC_DIR/gfortran" >> $CMDFILE
echo "" >> $CMDFILE
echo "module load cuda/11.5.0" >> $CMDFILE
echo "module load cmake/3.21.4" >> $CMDFILE
echo "" >> $CMDFILE
echo "export CC=mpicc CXX=mpicxx FC=mpif90 F90=mpif90 F77=mpif77" >> $CMDFILE
echo "" >> $CMDFILE
#echo "srun -n $ntasks $bin --backend CUDA --device-id 0 --setup $case &> logfile" >> $CMDFILE # don't use! segfaults!
echo "mpirun -np $ntasks $bin -i $case.i --nekrs-setup $nrscase --nekrs-backend CUDA --nekrs-device-id 0 &> logfile" >> $CMDFILE

sbatch $CMDFILE
squeue -u `whoami`
