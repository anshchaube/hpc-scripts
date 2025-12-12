#!/bin/bash

module purge
module load PrgEnv-gnu
module load Core/24.07

module load gcc/12.2.0
module load craype-accel-amd-gfx90a
module load cray-mpich/8.1.27
module load rocm
module unload cray-libsci
module load cmake/3.27
module list

export OCCA_HIP_ENABLED=1

export CC=mpicc
export CXX=mpic++
export FC=mpif77

export JOBS=16

export NEKRS_HOME=$(realpath -P /storage/home/afc6440/work/nekrs-install)
cd $NEKRS_HOME
echo | CC=mpicc CXX=mpic++ FC=mpif77 ./nrsconfig -DCMAKE_INSTALL_PREFIX=$NEKRS_HOME
