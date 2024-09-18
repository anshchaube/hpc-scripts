module purge
module load openmpi/4.1.1-pmi2
module load gcc/9.1.0

export GCC_DIR=/storage/icds/RISE/sw8/gcc/gcc-9.1.0/bin/
export PATH=$GCC_DIR:$PATH
export OMPI_CC=$GCC_DIR/gcc
export OMPI_CXX=$GCC_DIR/g++
export OMPI_FC=$GCC_DIR/gfortran

export CC=mpicc
export CXX=mpic++
export FC=mpif77

export NEK_SOURCE_ROOT=/storage/work/afc6440/Nek5000
export PATH=$NEK_SOURCE_ROOT/bin:$PATH

module load cuda/11.5.0 # only works with gcc 9, no gcc 10 or 11 available
module load cmake/3.21.4

export NEKRS_HOME=/storage/home/afc6440/work/nekrs-install
