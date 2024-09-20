#!/bin/bash
#SBATCH --job-name=nek_master
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
# #SBATCH --gpus-per-task=1
# #SBATCH --gpu-bind=closest
#SBATCH --mem=64G
#SBATCH --exclusive
#SBATCH --account=ebm5351_b_gpu
#SBATCH --partition=sla-prio

export CARDINAL_DIR=$(realpath -P /storage/work/afc6440/cardinal)
export NEKRS_HOME=$CARDINAL_DIR/install
module purge
module load anaconda/2023.09
conda activate cardinal
module load openmpi/4.1.1-pmi2

module load gcc/9.1.0
export GCC_DIR=/storage/icds/RISE/sw8/gcc/gcc-9.1.0/bin/
export PATH=$GCC_DIR:$PATH 
export OMPI_CC=$GCC_DIR/gcc
export OMPI_CXX=$GCC_DIR/g++
export OMPI_FC=$GCC_DIR/gfortran

module load cuda/11.5.0
module load cmake/3.21.4

export CC=mpicc CXX=mpicxx FC=mpif90 F90=mpif90 F77=mpif77
export PYTHONPATH=$CARDINAL_DIR/contrib/moose/python
export MOOSE_DIR=$CARDINAL_DIR/contrib/moose
export LIBMESH_DIR=$MOOSE_DIR/libmesh

echo "$PYTHONPATH"
echo "$MOOSE_DIR"
echo "$LIBMESH_DIR"

cd $CARDINAL_DIR
./run_tests -j 32 >& testlog
