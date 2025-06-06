#!/bin/bash
#SBATCH --job-name=JOBNAME
#SBATCH --time=00:15:00
#SBATCH --nodes=2
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
    # SHMEM
    for exe in osu_oshm_put \
               osu_oshm_get \
               osu_oshm_put_bw \
               osu_oshm_get_bw; do

        echo "Run $exe benchmark using $nodes nodes and 2 tasks."
        srun -v --nodes=$nodes \
             --ntasks=2 \
             --unbuffered \
             --distribution=block:block \
             --hint=nomultithread \
             --output "MACHINE-nodes-$nodes-$exe" \
             ${install_dir}/openshmem/$exe heap
    done
    for exe in osu_oshm_barrier; do

        echo "Run $exe benchmark using $nodes nodes and NTASKS tasks."
        srun -v --nodes=$nodes \
             --ntasks=NTASKS \
             --unbuffered \
             --distribution=block:block \
             --hint=nomultithread \
             --output "MACHINE-nodes-$nodes-$exe" \
             ${install_dir}/openshmem/$exe
    done
    # MPI-3 RMA
    for exe in osu_get_latency \
               osu_put_latency \
               osu_get_bw \
               osu_put_bw; do

        for syn in lock flush; do
            echo "Run $exe with $syn synchronisation benchmark using $nodes and 2 tasks."
            srun --nodes=$nodes \
                 --ntasks=2 \
                 --unbuffered \
                 --distribution=block:block \
                 --hint=nomultithread \
                 --output "MACHINE-nodes-$nodes-${exe}_${syn}" \
                 ${install_dir}/mpi/one-sided/$exe  -w allocate -s $syn
        done
    done
    # MPI-3 P2P
    for exe in osu_latency \
               osu_bw; do
        echo "Run $exe benchmark using $nodes nodes and 2 tasks."
        srun --nodes=$nodes \
             --ntasks=2 \
             --unbuffered \
             --distribution=block:block \
             --hint=nomultithread \
             --output "MACHINE-nodes-$nodes-$exe" \
            ${install_dir}/mpi/pt2pt/$exe
    done

    for exe in osu_allreduce; do
        echo "Run $exe benchmark using $nodes nodes and NTASKS tasks."
        srun --nodes=$nodes \
             --ntasks=NTASKS \
             --unbuffered \
             --distribution=block:block \
             --hint=nomultithread \
             --output "MACHINE-nodes-$nodes-$exe" \
            ${install_dir}/mpi/collective/$exe
    done
done
