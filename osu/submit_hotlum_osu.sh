#!/bin/bash
#SBATCH --job-name=JOBNAME
#SBATCH --output=%x.o%j
#SBATCH --time=00:30:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=64
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
# Set the number of threads to 1
#   This prevents any threaded system libraries from automatically
#   using threading.
export OMP_NUM_THREADS=1
export OMP_PLACES=cores

# Set the eager limit
# (see also https://docs.archer2.ac.uk/user-guide/tuning/#setting-the-eager-limit-on-archer2)
export FI_OFI_RXM_SAR_LIMIT=64K

export SRUN_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK

echo "Loading the Cray Compiling Environment (CCE)"
module load PrgEnv-cray
module load cce
module load cray-mpich
module load cray-dsmml
module load cray-openshmemx

# load latest modules
module load cpe/24.11
export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH

module list

install_dir=INSTALL_DIR/libexec/osu-micro-benchmarks

for nodes in 1 2; do
    for exe in  osu_oshm_put \
                osu_oshm_get \
                osu_oshm_barrier \
                osu_oshm_put_bw \
                osu_oshm_get_bw; do

        echo "Run $exe benchmark using $nodes and NTASKS tasks:"
        sbcast --compress=none ${install_dir}/openshmem/$exe /tmp/$exe
        srun -v --nodes=$nodes \
             --ntasks=NTASKS \
             --unbuffered \
             --distribution=block:block \
             --hint=nomultithread \
             /tmp/$exe
    done
    for exe in  "osu_get_latency -w allocate -s lock" \
                "osu_get_latency -w allocate -s flush" \
                "osu_put_latency -w allocate -s lock" \
                "osu_put_latency -w allocate -s flush"  \
                "osu_get_bw -w allocate -s lock" \
                "osu_get_bw -w allocate -s flush" \
                "osu_put_bw -w allocate -s lock" \
                "osu_put_bw -w allocate -s flush" \
                osu_latency \
                osu_bw \
                osu_allreduce; do

        echo "Run $exe benchmark using $nodes and NTASKS tasks:"
        sbcast --compress=none ${install_dir}/mpi/$exe /tmp/$exe
        srun --nodes=$nodes \
             --ntasks=NTASKS \
             --unbuffered \
             --distribution=block:block \
             --hint=nomultithread \
            /tmp/$exe
    done
done
