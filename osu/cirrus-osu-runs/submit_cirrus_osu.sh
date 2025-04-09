#!/bin/bash
#SBATCH --job-name=cirrus-osu
#SBATCH --time=00:15:00
#SBATCH --nodes=2
#SBATCH --cpus-per-task=1
#SBATCH --switches=1
#SBATCH --account=e710
#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --exclusive
#SBATCH --distribution=block:block

# Set the number of threads to 1
#   This prevents any threaded system libraries from automatically
#   using threading.
export OMP_NUM_THREADS=1
export OMP_PLACES=cores

# Set the eager limit
# (see also https://docs.archer2.ac.uk/user-guide/tuning/#setting-the-eager-limit-on-archer2)
export FI_OFI_RXM_SAR_LIMIT=64K

echo "Loading the GNU Compiler Collection (GCC)"
module load libtool/2.4.7
module load gcc/10.2.0
module load openmpi/4.1.6

echo "Setting SHMEM symmetric size"
export SHMEM_SYMMETRIC_SIZE=1G

module list

install_dir=/work/e710/e710/mf248/parcel-clustering-data/osu/install/libexec/osu-micro-benchmarks

for nodes in 1 2; do
    # SHMEM
    for exe in osu_oshm_put \
               osu_oshm_get \
               osu_oshm_put_bw \
               osu_oshm_get_bw; do

        echo "Run $exe benchmark using $nodes nodes and 2 tasks."
        srun --kill-on-bad-exit \
	     --nodes=$nodes \
             --ntasks=2 \
             --unbuffered \
             --distribution=block:block \
             --output "cirrus-nodes-$nodes-$exe" \
             ${install_dir}/openshmem/$exe heap
    done

    for exe in osu_oshm_barrier; do
        echo "Run $exe benchmark using $nodes nodes and 36 tasks."
        srun --kill-on-bad-exit \
	     --nodes=$nodes \
             --ntasks=36 \
             --unbuffered \
             --distribution=block:block \
             --output "cirrus-nodes-$nodes-$exe" \
             ${install_dir}/openshmem/$exe
    done
    # MPI-3 RMA
    for exe in osu_get_latency \
               osu_put_latency \
               osu_get_bw \
               osu_put_bw; do

        for syn in lock flush; do
            echo "Run $exe with $syn synchronisation benchmark using $nodes nodes and 2 tasks."
            srun --kill-on-bad-exit \
		 --nodes=$nodes \
                 --ntasks=2 \
                 --unbuffered \
                 --distribution=block:block \
                 --hint=nomultithread \
                 --output "cirrus-nodes-$nodes-${exe}_${syn}" \
                 ${install_dir}/mpi/one-sided/$exe -w allocate -s $syn
        done
    done
    # MPI-3 P2P
    for exe in osu_latency \
               osu_bw; do

        echo "Run $exe benchmark using $nodes nodes and 2 tasks."
        srun --kill-on-bad-exit \
             --nodes=$nodes \
             --ntasks=2 \
             --unbuffered \
             --distribution=block:block \
             --hint=nomultithread \
             --output "cirrus-nodes-$nodes-$exe" \
             ${install_dir}/mpi/pt2pt/$exe
    done

    for exe in osu_allreduce; do
        echo "Run $exe benchmark using $nodes nodes and 36 tasks."
        srun --kill-on-bad-exit \
	     --nodes=$nodes \
             --ntasks=36 \
             --unbuffered \
             --distribution=block:block \
             --hint=nomultithread \
             --output "cirrus-nodes-$nodes-$exe" \
             ${install_dir}/mpi/collective/$exe
    done
done

