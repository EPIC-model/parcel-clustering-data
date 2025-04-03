#!/bin/bash
#SBATCH --job-name=hotlum-cray-read
#SBATCH --output=%x.o%j
#SBATCH --time=01:40:00
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

#export FI_MR_CACHE_MONITOR=memhooks
#export FI_CXI_RX_MATCH_MODE=software
#export FI_CXI_REQ_BUF_SIZE=25165824

export SRUN_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK

export MPLCONFIGDIR=$PWD

if test "cray" = "gnu"; then
    echo "Loading the GNU Compiler Collection (GCC)"
    module load PrgEnv-gnu
    module load cray-hdf5-parallel
    module load cray-netcdf-hdf5parallel
    module load cray-dsmml
    module load cray-openshmemx
    module load cpe/24.11
    export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CRAY_NETCDF_HDF5PARALLEL_PREFIX/lib
elif test "cray" = "cray"; then
    echo "Loading the Cray Compiling Environment (CCE)"
    module load PrgEnv-cray
    module load cce
    module load cray-mpich
    module load cray-hdf5-parallel
    module load cray-netcdf-hdf5parallel
    module load cray-dsmml
    module load cray-openshmemx

    # load latest modules
    module load -f cpe/24.11
    export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CRAY_NETCDF_HDF5PARALLEL_PREFIX/lib
fi

echo "Running on $SLURM_N2 nodes with $SLURM_NTASKS tasks."

module list

bin_dir=/lus/bnchlu1/shanks/EPIC/310325/parcel-clustering/build_cce/bin
PATH=${bin_dir}:$PATH
EXE=${bin_dir}/benchmark_read
export MPIR_CVAR_CH4_OFI_ENABLE_RMA=0
#export SHMEM_SYMMETRIC_SIZE=1G

#sbcast --compress=none ${bin_dir}/benchmark_read /tmp/benchmark_read
for i in $(seq 1 10); do
    srun --nodes=2 \
        --ntasks=128 \
        --unbuffered \
        --distribution=block:block \
        --hint=nomultithread \
        ${bin_dir}/benchmark_read \
        --dirname /lus/bnchlu1/shanks/EPIC/data/rt-128x128x128/early-time \
        --ncbasename epic_rt_128x128x128_early \
        --niter 10 \
        --offset 1 \
        --nfiles 10 \
        --size-factor 1.5 \
        --csvfname "hotlum-cray-shmem-read-early-nx-128-ny-128-nz-128-nodes-2" \
        --comm-type "shmem"
    for g in "p2p" "rma"; do
        srun --nodes=2 \
            --ntasks=128 \
            --unbuffered \
            --distribution=block:block \
            --hint=nomultithread \
            ${bin_dir}/benchmark_read \
            --dirname /lus/bnchlu1/shanks/EPIC/data/rt-128x128x128/early-time \
            --ncbasename epic_rt_128x128x128_early \
            --niter 10 \
            --offset 1 \
            --nfiles 10 \
            --size-factor 1.5 \
            --csvfname "hotlum-cray-$g-read-early-nx-128-ny-128-nz-128-nodes-2" \
            --comm-type "$g"

        if test "true" = "true"; then
            srun --nodes=2 \
                --ntasks=128 \
                --unbuffered \
                --distribution=block:block \
                --hint=nomultithread \
                ${bin_dir}/benchmark_read \
                --dirname /lus/bnchlu1/shanks/EPIC/data/rt-128x128x128/early-time \
                --ncbasename epic_rt_128x128x128_early \
                --niter 10 \
                --offset 1 \
                --nfiles 10 \
                --size-factor 1.5 \
                --csvfname "hotlum-cray-$g-read-early-nx-128-ny-128-nz-128-nodes-2-subcomm" \
                --comm-type "$g" \
                --subcomm
        fi
    done
done
