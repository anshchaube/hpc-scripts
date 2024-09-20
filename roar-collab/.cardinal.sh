#### CARDINAL SETTINGS #######################################
module purge

#module load openmpi/5.0.3 #- executes N serial jobs, also causes some build issues occasionally
#module load openmpi/4.1.4 #- pmi complaint
module load anaconda/2023.09
conda activate cardinal

module load openmpi/4.1.1-pmi2 
module load gcc/9.1.0
export GCC_DIR=/storage/icds/RISE/sw8/gcc/gcc-9.1.0/bin

export PATH=$GCC_DIR:$PATH 
export OMPI_CC=$GCC_DIR/gcc
export OMPI_CXX=$GCC_DIR/g++
export OMPI_FC=$GCC_DIR/gfortran

module load cuda/11.5.0 # only works with gcc 9, no gcc 10 or 11 available
module load cmake/3.21.4
#module load python/3.11.2

#export CC=mpicc CXX=mpic++ FC=mpif90
export CC=mpicc CXX=mpicxx FC=mpif90 F90=mpif90 F77=mpif77
export ENABLE_OPENMC=false


export CARDINAL_DIR=$(realpath -P /storage/home/afc6440/work/cardinal)
export NEKRS_HOME=$CARDINAL_DIR/install
export PYTHONPATH=$CARDINAL_DIR/contrib/moose/python
export MOOSE_DIR=$CARDINAL_DIR/contrib/moose
export LIBMESH_DIR=$MOOSE_DIR/libmesh############################################################

