#!/bin/bash

module purge
module load PrgEnv-gnu
module load Core/24.07

module load ums/default ums002/default cray-python
pip install --user pyyaml jinja2 packaging

module load gcc/12.2.0
module load craype-accel-amd-gfx90a
module load cray-mpich/8.1.27
module load rocm
module unload cray-libsci
module load cmake/3.27
module list

export OCCA_HIP_ENABLED=1
export ENABLE_OPENMC=false

export CARDINAL_DIR=$(realpath -P /lustre/orion/scratch/achaube/cfd202/cardinal)
export NEKRS_HOME=$CARDINAL_DIR/install
echo "Default MOOSE python path:${PYTHONPATH}"
export PYTHONPATH=$CARDINAL_DIR/contrib/moose/python:$PYTHONPATH
export MOOSE_DIR=$CARDINAL_DIR/contrib/moose
export LIBMESH_DIR=$MOOSE_DIR/libmesh/installed

echo $CARDINAL_DIR
echo $NEKRS_HOME
echo $PYTHON_PATH
echo $MOOSE_DIR
echo $LIBMESH_DIR

export JOBS=16
export LIBMESH_JOBS=$JOBS
export MOOSE_JOBS=$JOBS

cd $CARDINAL_DIR

# clean install
rm *.log
rm -rf build/
rm -rf install/
rm -rf contrib/*

./scripts/get-dependencies.sh > dep.log

./contrib/moose/scripts/update_and_rebuild_petsc.sh &> petsc.log

# libmesh error fix: https://github.com/idaholab/moose/discussions/18868
cd contrib/moose/libmesh
git submodule sync
cd $CARDINAL_DIR

./contrib/moose/scripts/update_and_rebuild_libmesh.sh --enable-xdr-required --with-xdr-include=/usr/include --with-vexcl=no &> libmesh.log
./contrib/moose/scripts/update_and_rebuild_wasp.sh &> wasp.log

make -j $JOBS OCCA_HIP_ENABLED=$OCCA_HIP_ENABLED  >& opt-make.log
METHOD=dbg make -j $JOBS OCCA_HIP_ENABLED=$OCCA_HIP_ENABLED >& dbg-make.log
