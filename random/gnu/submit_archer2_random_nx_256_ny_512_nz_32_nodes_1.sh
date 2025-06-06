#!/bin/bash
#SBATCH --job-name=gnu-random
#SBATCH --output=%x.o%j
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
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

if test "gnu" = "gnu"; then
    echo "Loading the GNU Compiler Collection (GCC)"
    module load PrgEnv-gnu
    module load cray-hdf5-parallel
    module load cray-netcdf-hdf5parallel
    module load cray-dsmml
    module load cray-openshmemx

    export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CRAY_NETCDF_HDF5PARALLEL_PREFIX/lib
elif test "gnu" = "cray"; then
    echo "Loading the Cray Compiling Environment (CCE)"
    module load PrgEnv-cray/8.3.3
    module load cce/15.0.0
    module load cray-mpich/8.1.23
    module load cray-hdf5-parallel/1.12.2.1
    module load cray-netcdf-hdf5parallel/4.9.0.1
    module load cray-dsmml/0.2.2
    module load cray-openshmemx/11.5.7

    # load latest modules
    module load cpe/23.09
    export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CRAY_NETCDF_HDF5PARALLEL_PREFIX/lib
fi

#export PGAS_MEMINFO_DISPLAY=1
#export XT_SYMMETRIC_HEAP_SIZE=1G
#export CRAY_PGAS_MAX_CONCURRENCY=1

echo "Setting SHMEM symmetric size"
export SHMEM_SYMMETRIC_SIZE=1G
export SHMEM_VERSION_DISPLAY=0
export SHMEM_ENV_DISPLAY=0

export SLURM_CPU_FREQ_REQ=2000000

echo "Running on $SLURM_N1 nodes with $SLURM_NTASKS tasks."

module list

bin_dir=/work/e710/e710/mf248/gnu/bin
PATH=${bin_dir}:$PATH

sbcast --compress=none ${bin_dir}/benchmark_random /tmp/benchmark_random
for i in $(seq 1 10); do
    srun --nodes=1 \
        --ntasks=128 \
        --unbuffered \
        --distribution=block:block \
        /tmp/benchmark_random \
        --nx 256 \
        --ny 512 \
        --nz 32 \
        --lx 80.0 \
        --ly 160.0 \
        --lz 10.0 \
        --min-vratio 20.0 \
        --nppc 20 \
        --niter 10 \
        --small-parcel-fraction 0.5 \
        --shuffle \
        --csvfname "archer2-gnu-shmem-random-nx-256-ny-512-nz-32-nodes-1" \
        --comm-type "shmem"
    for g in "p2p" "rma"; do
        srun --nodes=1 \
            --ntasks=128 \
            --unbuffered \
            --distribution=block:block \
            --hint=nomultithread \
            /tmp/benchmark_random \
            --nx 256 \
            --ny 512 \
            --nz 32 \
            --lx 80.0 \
            --ly 160.0 \
            --lz 10.0 \
            --min-vratio 20.0 \
            --nppc 20 \
            --niter 10 \
            --small-parcel-fraction 0.5 \
            --shuffle \
            --csvfname "archer2-gnu-$g-random-nx-256-ny-512-nz-32-nodes-1" \
            --comm-type "$g"

        if test "false" = "true"; then
            srun --nodes=1 \
                --ntasks=128 \
                --unbuffered \
                --distribution=block:block \
                --hint=nomultithread \
                /tmp/benchmark_random \
                --nx 256 \
                --ny 512 \
                --nz 32 \
                --lx 80.0 \
                --ly 160.0 \
                --lz 10.0 \
                --min-vratio 20.0 \
                --nppc 20 \
                --niter 10 \
                --small-parcel-fraction 0.5 \
                --shuffle \
                --csvfname "archer2-gnu-$g-random-nx-256-ny-512-nz-32-nodes-1-subcomm" \
                --comm-type "$g" \
                --subcomm
        fi
    done
done

