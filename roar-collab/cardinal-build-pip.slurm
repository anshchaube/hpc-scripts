#!/bin/bash
#SBATCH --job-name=bldcardy
#SBATCH --time=6:30:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --gpus=1
#SBATCH --exclusive
#SBATCH --account=ebm5351_b_gpu
#SBATCH --partition=sla-prio

# before launching this, load the python 3.11 module
# execute the command below ONCE
# pip install --user packaging pyaml jinja2
# If you are unsure whether you have these packages now or in the future,
# you can check by loading the same python module, then executing
# pip show packaging pyaml jinja2

module purge
module load python/3.11.2
module load openmpi/4.1.1-pmi2 
module load gcc/9.1.0

export GCC_DIR=/storage/icds/RISE/sw8/gcc/gcc-9.1.0/bin/
export PATH=$GCC_DIR:$PATH 
export OMPI_CC=$GCC_DIR/gcc
export OMPI_CXX=$GCC_DIR/g++
export OMPI_FC=$GCC_DIR/gfortran

module load cuda/11.5.0 # only works with gcc 9, no gcc 10 or 11 available
module load cmake/3.21.4

export OCCA_CUDA_ENABLED=1

export CC=mpicc CXX=mpicxx FC=mpif90 F90=mpif90 F77=mpif77

export CARDINAL_DIR=$(realpath -P /storage/home/afc6440/work/cardinal)
export NEKRS_HOME=$CARDINAL_DIR/install
echo "Default MOOSE python path:${PYTHONPATH}"
export PYTHONPATH=$CARDINAL_DIR/contrib/moose/python
export MOOSE_DIR=$CARDINAL_DIR/contrib/moose
export LIBMESH_DIR=$MOOSE_DIR/libmesh

export JOBS=32
export LIBMESH_JOBS=32
export MOOSE_JOBS=32
export ENABLE_OPENMC=false # takes care of any lingering `true` values, not needed if your bashrc/env is clean

cd $CARDINAL_DIR

rm *.log
rm -rf contrib/moose
rm -rf build/ install/

./scripts/get-dependencies.sh &> dependency.log

./contrib/moose/scripts/update_and_rebuild_petsc.sh &> petsc-build.log
./contrib/moose/scripts/update_and_rebuild_libmesh.sh &> libmesh-build.log
./contrib/moose/scripts/update_and_rebuild_wasp.sh &> wasp-build.log

make -j $JOBS OCCA_CUDA_ENABLED=$OCCA_CUDA_ENABLED &> opt-make.log # cardinal-opt
METHOD=dbg make -j $JOBS OCCA_CUDA_ENABLED=$OCCA_CUDA_ENABLED &> dbg-make.log # cardinal-dbg
