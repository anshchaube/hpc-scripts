#!/bin/bash

: ${EXCL_MODE:=1} # run in exclusive mode or not
: ${MEM_PER_TASK:=NULL} # memory adjustment for large tasks/restart files


if [ $# -lt 2 ] || [ $# -gt 4 ]; then
  echo "usage:$0 <no. of nodes> <walltime hh:mm:ss> [<gpus/cpus per node=2>] [nek_par_name]"
  echo "One NekRS .par file detected automatically and supplied"
  echo "Multiple pars in same dir - supply 4th argument."
  echo "Default value of 3rd argument optimized for GPUs per node."
  exit 0
fi

export NEKRS_HOME=$(realpath -P /storage/home/afc6440/work/david_cardinal_2/cardinal/install)
bin=${NEKRS_HOME}/bin/nekrs

CMDFILE=nrs.slurm

nnodes=$1
time=$2

tasks_per_node=${3:-2} # for NekRS cases
ntasks=$((nnodes*tasks_per_node))

nrs_case=""

if [ $# -eq 5 ]; then
  nrs_case=${5}
else
  if [ ! -f $PWD/*.par ]; then
      echo "No NekRS par file detected! ABORT"
      exit 1
  else
      s=$(find * -maxdepth 0 -name '*.par' -o -name -print)
      echo "Detected $s!"
      nrs_case=$(basename -- "$s")
      nrs_case="${nrs_case%.*}"
      echo "NEKRS CASE NAME: $nrs_case"
  fi
fi

echo "#!/bin/bash" > $CMDFILE
echo "#SBATCH --job-name=$case" >> $CMDFILE
echo "#SBATCH --time=$time" >> $CMDFILE
echo "#SBATCH --nodes=$nnodes" >> $CMDFILE
echo "#SBATCH --ntasks-per-node=$tasks_per_node" >> $CMDFILE

if [ $EXCL_MODE -eq 1 ]; then
  echo "#SBATCH --exclusive" >> $CMDFILE
elif [[ $EXCL_MODE -eq 0 && $nrs_check ]]; then
  echo "#SBATCH --cpus-per-gpu=1"  >> $CMDFILE # allows you to request more GPUs w/o hitting CPU limit on roar
fi

echo "#SBATCH --gpus-per-task=1" >> $CMDFILE
echo "#SBATCH --gpu-bind=closest" >> $CMDFILE
echo "#SBATCH --account=ebm5351_b_gpu" >> $CMDFILE
echo "#SBATCH --partition=sla-prio" >> $CMDFILE
if [ "$MEM_PER_TASK" != "NULL" ]; then
  echo "#SBATCH --mem-per-gpu=$MEM_PER_TASK" >> $CMDFILE
fi
echo "" >> $CMDFILE

echo "export NEKRS_HOME=$NEKRS_HOME" >> $CMDFILE

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
