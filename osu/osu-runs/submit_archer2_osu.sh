#!/bin/bash
#SBATCH --job-name=archer2-osu
#SBATCH --output=%x.o%j
#SBATCH --time=00:30:00
#SBATCH --nodes=2
#SBATCH --cpus-per-task=1
#SBATCH --constraint=StandardMem
#SBATCH --switches=1
#SBATCH --account=e710
#SBATCH --partition=standard
#SBATCH --qos=standard

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
module load PrgEnv-cray/8.3.3
module load cce/15.0.0
module load cray-mpich/8.1.23
module load cray-dsmml/0.2.2
module load cray-openshmemx/11.5.7

# load latest modules
module load cpe/23.09
export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH

echo "Setting SHMEM symmetric size"
export SHMEM_SYMMETRIC_SIZE=1G
# export SHMEM_VERSION_DISPLAY=0
# export SHMEM_ENV_DISPLAY=0

export SLURM_CPU_FREQ_REQ=2000000

module list

install_dir=/work/e710/e710/mf248/parcel-clustering-data/osu/install/libexec/osu-micro-benchmarks

for nodes in 1 2; do
    # SHMEM
    for exe in osu_oshm_put \
               osu_oshm_get \
               osu_oshm_put_bw \
               osu_oshm_get_bw; do

        echo "Run $exe benchmark using $nodes nodes and 2 tasks:"
        srun --nodes=$nodes \
             --ntasks=2 \
             --unbuffered \
             --distribution=block:block \
             ${install_dir}/openshmem/$exe heap
    done

    for exe in osu_oshm_barrier; do
        echo "Run $exe benchmark using $nodes nodes and 128 tasks:"
        srun --nodes=$nodes \
             --ntasks=128 \
             --unbuffered \
             --distribution=block:block \
             ${install_dir}/openshmem/$exe
    done
    # MPI-3 RMA
    for exe in osu_get_latency \
               osu_put_latency \
               osu_get_bw \
               osu_put_bw; do

        for syn in lock flush; do
            echo "Run $exe with $syn synchronisation benchmark using $nodes nodes and 2 tasks:"
            srun --nodes=$nodes \
                 --ntasks=2 \
                 --unbuffered \
                 --distribution=block:block \
                 --hint=nomultithread \
                 ${install_dir}/mpi/one-sided/$exe -w allocate -s $syn
        done
    done
    # MPI-3 P2P
    for exe in osu_latency \
               osu_bw; do

        echo "Run $exe benchmark using $nodes nodes and 2 tasks:"
        srun --nodes=$nodes \
             --ntasks=2 \
             --unbuffered \
             --distribution=block:block \
             --hint=nomultithread \
             ${install_dir}/mpi/pt2pt/$exe
    done

    for exe in osu_allreduce; do
        echo "Run $exe benchmark using $nodes nodes and 128 tasks:"
        srun --nodes=$nodes \
             --ntasks=128 \
             --unbuffered \
             --distribution=block:block \
             --hint=nomultithread \
             ${install_dir}/mpi/collective/$exe
    done
done

