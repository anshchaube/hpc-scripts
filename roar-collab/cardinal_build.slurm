#!/bin/bash
#SBATCH --job-name=bldcardy
#SBATCH --time=2:30:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --gpus=1
#SBATCH --exclusive
#SBATCH --account=ebm5351_b_gpu
#SBATCH --partition=sla-prio

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

module load cuda/11.5.0 # only works with gcc 9, no gcc 10 or 11 available
module load cmake/3.21.4
#module load python/3.11.2

export CC=mpicc CXX=mpicxx FC=mpif90 F90=mpif90 F77=mpif77
export ENABLE_OPENMC=false

export CARDINAL_DIR=$(realpath -P /storage/home/afc6440/work/cardinal)
export NEKRS_HOME=$CARDINAL_DIR/install
export PYTHONPATH=$CARDINAL_DIR/contrib/moose/python
export MOOSE_DIR=$CARDINAL_DIR/contrib/moose
export LIBMESH_DIR=$MOOSE_DIR/libmesh

export JOBS=32
export LIBMESH_JOBS=32
export MOOSE_JOBS=32

cd $CARDINAL_DIR
./scripts/get-dependencies.sh &> dependency.log

./contrib/moose/scripts/update_and_rebuild_petsc.sh &> petsc-build.log
./contrib/moose/scripts/update_and_rebuild_libmesh.sh &> libmesh-build.log
./contrib/moose/scripts/update_and_rebuild_wasp.sh &> wasp-build.log

make -j 32 &> cardinal-make.log # cardinal-opt
# METHOD=dbg make -j 32 # cardinal-dbg -> doesn't work with OpenMC enables
