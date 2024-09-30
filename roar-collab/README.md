## Overview

The group has the following usage limits: 10 GPUs max at a time, 240 CPUs max at a time.
There is no limit on how many nodes you can request.
Once these quotas are hit, further jobs have to wait in queue.

Using the group account `ebm....` by default requests GPU nodes (with A100, not V100).

To maximize efficiency, GPU jobs should not request too many CPUs, and CPU based runs 
should not request GPU-based nodes (i.e. avoid using the group allocation because that 
requests GPU-based nodes only, unless it's an emergency).

Exclusive mode (#SBATCH --exclusive) is good for performance in large cases but for smaller cases and 
debugging, it's not necessary. Comment out that command and you may be able to request CPUs from many
nodes to get around any group limits.

To coordinate, Slack can be used. You can also see who's running what job using

`squeue | grep <PSU ID>`

To see a list of available nodes and partitions, see `roar-system-info.txt`

For CPU-only runs, avoid saturating all CPUs on a node to prevent MPI issues.

There is a central `bashrc` available, that loads modules and environment variables
 appropriate for each code. Many commands there are redundant with respect to 
the job or build scripts. Consider having a clean `bashrc` and just setting your
preferred variables in a bash or SLURM job script, especially if running multiple versions
 of Nek or Cardinal.

###############################################################################

## Nek5000

Use the script `nek5k_roar.sh` to run. `nek5k.sh` has env variables.

###############################################################################

## NekRS

The script to build NekRS is `build.slurm`. Note that the login and GPU nodes have
a different setup. Compiling on login nodes then running on GPU nodes causes errors.
 Please use the script to build NekRS on a GPU node.

`nekrs_roar.sh` runs jobs.

###############################################################################

## Cardinal

Prior to the first build, load the suggested anaconda module.

Create a conda environment and activate (default name in scripts - Cardinal)

Tie it to python v3.11.2 as that is the max version supported by MOOSE: `conda create -n cardinal python=3.11.2`

`conda install pyaml jinja2 packaging` (source:https://mooseframework.inl.gov/getting_started/installation/hpc_install_moose.html)

Proceed to compile cardinal using the `cardinal_build.slurm` script.

Jobs are run with `cardinal_roar.sh`

Env. variables are in `.cardinal.sh`. `bashrc` setup should be optional since the scripts have everything you need.
