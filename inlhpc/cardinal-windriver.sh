#!/bin/bash

: ${EXCL_MODE:=1} # run in exclusive mode or not
: ${MEM_PER_TASK:=NULL} # memory adjustment for large tasks/restart files


if [ $# -lt 3 ] || [ $# -gt 5 ]; then
  echo "usage:$0 <moose file, w/ .i> <no. of nodes> <walltime hh:mm:ss> [<cpus per node=96>] [nek_par_name]"
  echo "One NekRS .par file detected automatically and supplied to cardinal-opt if script is in input-file dir."
  echo "Multiple pars in same dir - supply 5th argument."
  exit 0
fi

# Revise for your Cardinal location
export CARDINAL_DIR=$HOME/cardinal

export NEKRS_HOME=$CARDINAL_DIR/install
export PYTHONPATH=$CARDINAL_DIR/contrib/moose/python
export MOOSE_DIR=$CARDINAL_DIR/contrib/moose

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
fi

echo "#SBATCH --cpus-per-task=1" >> $CMDFILE
echo "#SBATCH --wckey=moose" >> $CMDFILE # will need GPU node if cardinal compiled with GPU support
if [ "$MEM_PER_TASK" != "NULL" ]; then
  echo "#SBATCH --mem-per-cpu=$MEM_PER_TASK" >> $CMDFILE
fi  
echo "" >> $CMDFILE

echo "export CARDINAL_DIR=${CARDINAL_DIR}" >> $CMDFILE
echo "export NEKRS_HOME=$CARDINAL_DIR/install" >> $CMDFILE
echo "export PYTHONPATH=$CARDINAL_DIR/contrib/moose/python" >> $CMDFILE
echo "export MOOSE_DIR=$CARDINAL_DIR/contrib/moose" >> $CMDFILE
echo "export LIBMESH_DIR=$MOOSE_DIR/libmesh" >> $CMDFILE
echo "module purge" >> $CMDFILE
echo "module load openmpi/4.1.5_ucx1.14.1 cmake/3.29.3" >> $CMDFILE
echo "" >> $CMDFILE
echo "export CC=mpicc CXX=mpicxx FC=mpif90" >> $CMDFILE
echo "" >> $CMDFILE

if $nrs_check; then
	echo "mpirun -np $ntasks $bin -i $case.i --nekrs-setup $nrs_case" >> $CMDFILE
else
	echo "mpirun -np $ntasks $bin -i $case.i" >> $CMDFILE
fi

sbatch $CMDFILE
squeue -u `whoami`
