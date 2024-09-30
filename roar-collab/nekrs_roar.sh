#!/bin/bash

if [ $# -lt 3 ] || [ $# -gt 5 ]; then
  echo "usage:$0 <casename> <no. of nodes> <time> [<gpus/node=2>] [<min mem=64 GB>]"
  exit 0
fi

case=$1
nnodes=$2
time=$3
ngpus_per_node=${4:-2}
mem="${5:-64G}" #min memory reqd

ntasks=$((nnodes*ngpus_per_node))

CMDFILE=$1.slurm
bin=${NEKRS_HOME}/bin/nekrs

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

echo "module purge" >> $CMDFILE
echo "module load openmpi/4.1.1-pmi2" >> $CMDFILE
echo "" >> $CMDFILE
echo "module load gcc/9.1.0" >> $CMDFILE
echo "export GCC_DIR=/storage/icds/RISE/sw8/gcc/gcc-9.1.0/bin" >> $CMDFILE
echo "export PATH=\$GCC_DIR:\$PATH " >> $CMDFILE
echo "export OMPI_CC=\$GCC_DIR/gcc" >> $CMDFILE
echo "export OMPI_CXX=\$GCC_DIR/g++" >> $CMDFILE
echo "export OMPI_FC=\$GCC_DIR/gfortran" >> $CMDFILE
echo "" >> $CMDFILE
echo "module load cuda/11.5.0" >> $CMDFILE
echo "module load cmake/3.21.4" >> $CMDFILE
echo "" >> $CMDFILE
echo "export CC=mpicc" >> $CMDFILE
echo "export CXX=mpic++" >> $CMDFILE
echo "export FC=mpif77" >> $CMDFILE
echo "" >> $CMDFILE
#echo "srun -n $ntasks $bin --backend CUDA --device-id 0 --setup $case &> logfile" >> $CMDFILE # don't use! segfaults!
echo "mpirun -n $ntasks $bin --backend CUDA --device-id 0 --setup $case &> logfile" >> $CMDFILE

sbatch $CMDFILE
squeue -u `whoami`
