#!/bin/bash

# script to build NekRS

#SBATCH --job-name=buildnrs
#SBATCH --time=0:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=12
#SBATCH --gpus=1
#SBATCH --account=ebm5351_b_gpu
#SBATCH --partition=sla-prio

module purge
module load openmpi/4.1.1-pmi2
#module load openmpi/5.0.3 #- executes N serial jobs

module load gcc/9.1.0
export GCC_DIR=/storage/icds/RISE/sw8/gcc/gcc-9.1.0/bin
export PATH=$GCC_DIR:$PATH
export OMPI_CC=$GCC_DIR/gcc
export OMPI_CXX=$GCC_DIR/g++
export OMPI_FC=$GCC_DIR/gfortran

module load cuda/11.5.0
module load cmake/3.21.4

export CC=mpicc
export CXX=mpic++
export FC=mpif77

export NEKRS_HOME=$(realpath -P /storage/home/afc6440/work/nekrs-install)
cd $NEKRS_HOME
echo | CC=mpicc CXX=mpic++ FC=mpif77 ./nrsconfig -DCMAKE_INSTALL_PREFIX=$NEKRS_HOME
