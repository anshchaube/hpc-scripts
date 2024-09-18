#!/bin/bash

if [ $# -lt 3 ] || [ $# -gt 5 ]; then
  echo "usage:$0 <casename> <no. of nodes> <time>  [<cpus/node=32>] [<min mem=64 GB>]"
  exit 0
fi

case=$1
nnodes=$2
time=$3
ncpus_per_node=${4:-32} # 48 total, don't saturate
mem="${5:-64G}" #min memory reqd, the max is 380G per node, system default for mem param - 4GB

ntasks=$((nnodes*ncpus_per_node))

CMDFILE=$1.slurm

echo "#!/bin/bash" > $CMDFILE
echo "#SBATCH --job-name=$case" >> $CMDFILE
echo "#SBATCH --time=$time" >> $CMDFILE
echo "#SBATCH --nodes=$nnodes" >> $CMDFILE
echo "#SBATCH --ntasks-per-node=$ncpus_per_node" >> $CMDFILE
echo "#SBATCH --mem=$mem" >> $CMDFILE # TODO: further tests
echo "#SBATCH --exclusive" >> $CMDFILE
echo "#SBATCH --account=ebm5351_b_gpu" >> $CMDFILE
echo "#SBATCH --partition=sla-prio" >> $CMDFILE
echo "" >> $CMDFILE

echo "module purge" >> $CMDFILE
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
echo "export CC=mpicc" >> $CMDFILE
echo "export CXX=mpic++" >> $CMDFILE
echo "export FC=mpif77" >> $CMDFILE
echo "" >> $CMDFILE
echo "cd \$SLURM_SUBMIT_DIR"  >> $CMDFILE
echo "\$SLURM_SUBMIT_DIR > SESSION.NAME"   >> $CMDFILE

echo "echo $case >>  SESSION.NAME" >> $CMDFILE
echo   "echo \`pwd\`'/' >> SESSION.NAME" >>  $CMDFILE

#echo "srun -n $ntasks ./nek5000 &> srun_logfile" >> $CMDFILE   # do NOT use this!!!
echo "mpirun -n $ntasks ./nek5000 &> logfile" >> $CMDFILE

sbatch $CMDFILE
squeue -u `whoami`
