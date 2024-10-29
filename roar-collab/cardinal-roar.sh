#!/bin/bash

: ${EXCL_MODE:=1} # run in exclusive mode or not
: ${MEM_PER_TASK:=NULL} # memory adjustment for large tasks/restart files


if [ $# -lt 3 ] || [ $# -gt 5 ]; then
  echo "usage:$0 <moose file, w/ .i> <no. of nodes> <walltime hh:mm:ss> [<gpus/cpus per node=2>] [nek_par_name]"
  echo "One NekRS .par file detected automatically and supplied to cardinal-opt if script is in input-file dir."
  echo "Multiple pars in same dir - supply 5th argument. No pars - defaults to MOOSE case run on GPU node (assuming GPU compiled Cardinal)"
  echo "Default value of 4th argument optimized for GPUs per node. For non-NekRS runs, adjust accordingly to maximize CPU usage!"
  exit 0
fi

export CARDINAL_DIR=$(realpath -P /storage/home/afc6440/work/david_cardinal_2/cardinal)
bin=${CARDINAL_DIR}/cardinal-opt
#bin=${CARDINAL_DIR}/cardinal-dbg

case=${1}
case="${case%.*}"
CMDFILE=$case.slurm

nnodes=$2
time=$3

nrs_check=true
tasks_per_node=${4:-2} # for NekRS cases
ntasks=$((nnodes*tasks_per_node))

nrs_case=""

if [ $# -eq 5 ]; then
  nrs_case=${5}
else
  if [ ! -f $PWD/*.par ]; then
      echo "No NekRS case, attempting to run CPU-based MOOSE case"
      nrs_check=false
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
  echo "#SBATCH --cpus-per-gpu=1"  >> $CMDFILE # allows you to request more GPUs w/o hitting CPU limit
fi

if $nrs_check; then
  echo "#SBATCH --gpus-per-task=1" >> $CMDFILE
  echo "#SBATCH --gpu-bind=closest" >> $CMDFILE
  echo "#SBATCH --account=ebm5351_b_gpu" >> $CMDFILE
  echo "#SBATCH --partition=sla-prio" >> $CMDFILE
  if [ "$MEM_PER_TASK" != "NULL" ]; then
    echo "#SBATCH --mem-per-gpu=$MEM_PER_TASK" >> $CMDFILE
  fi
else
  echo "#SBATCH --cpus-per-task=1" >> $CMDFILE
  echo "#SBATCH --account=ebm5351_b_gpu" >> $CMDFILE # will need GPU node if cardinal compiled with GPU support
  echo "#SBATCH --partition=sla-prio" >> $CMDFILE
#  echo "#SBATCH --partition=open" >> $CMDFILE # use the open partition you compiled cardinal without gpu support, change cardinal_dir accordingly
  if [ "$MEM_PER_TASK" != "NULL" ]; then
    echo "#SBATCH --mem-per-cpu=$MEM_PER_TASK" >> $CMDFILE
  fi  
fi
echo "" >> $CMDFILE

echo "export CARDINAL_DIR=${CARDINAL_DIR}" >> $CMDFILE
echo "export NEKRS_HOME=$CARDINAL_DIR/install" >> $CMDFILE
echo "export PYTHONPATH=$CARDINAL_DIR/contrib/moose/python" >> $CMDFILE
echo "export MOOSE_DIR=$CARDINAL_DIR/contrib/moose" >> $CMDFILE
echo "export LIBMESH_DIR=$MOOSE_DIR/libmesh" >> $CMDFILE
echo "module purge" >> $CMDFILE
echo "module load anaconda/2023.09" >> $CMDFILE
echo "conda activate david-cardinal" >> $CMDFILE
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

if $nrs_check; then
	echo "mpirun -np $ntasks $bin -i $case.i --nekrs-setup $nrs_case --nekrs-backend CUDA --nekrs-device-id 0" >> $CMDFILE
else
	echo "mpirun -np $ntasks $bin -i $case.i" >> $CMDFILE
fi

sbatch $CMDFILE
squeue -u `whoami`
