#!/bin/bash
#SBATCH --job-name=hotlum-cray-random
#SBATCH --output=%x.o%j
#SBATCH --time=01:00:00
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=64
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH -x x1003c6s1b0n[0-1],x1000c2s1b0n[0-1],x1003c7s4b1n[0-1],x1003c7s3b0n[0-1],x1000c2s1b1n[0-1],x1000c2s2b0n[0-1],x1000c2s2b1n[0-1],x1000c2s3b0n[0-1],x1000c2s3b1n[0-1],x1003c7s3b1n[0-1],x1003c7s4b0n[0-1],x1003c7s6b0n[0-1],x1003c7s6b1n[0-1],x1003c7s5b1n[0-1],x1003c6s1b1n[0-1],x1003c6s2b0n[0-1],x1003c6s2b1n[0-1],x1003c6s3b0n[0-1]

# Set the number of threads to 1
#   This prevents any threaded system libraries from automatically
#   using threading.
export OMP_NUM_THREADS=1
export OMP_PLACES=cores

# Set the eager limit
# (see also https://docs.archer2.ac.uk/user-guide/tuning/#setting-the-eager-limit-on-archer2)
export FI_OFI_RXM_SAR_LIMIT=64K

export SRUN_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK

export MPLCONFIGDIR=$PWD

if test "cray" = "gnu"; then
    echo "Loading the GNU Compiler Collection (GCC)"
    module switch PrgEnv-cray PrgEnv-gnu
    module load cray-hdf5-parallel
    module load cray-netcdf-hdf5parallel
    module load cray-dsmml
    module load cray-openshmemx
    module load cpe/24.11
    export NETCDF_C_DIR=$CRAY_NETCDF_HDF5PARALLEL_PREFIX
    export NETCDF_FORTRAN_DIR=$CRAY_NETCDF_HDF5PARALLEL_PREFIX
    export FC=ftn
    export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
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
    module load cpe/24.11
    export NETCDF_C_DIR=$CRAY_NETCDF_HDF5PARALLEL_PREFIX
    export NETCDF_FORTRAN_DIR=$CRAY_NETCDF_HDF5PARALLEL_PREFIX
    export FC=ftn
    export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
fi

#export MPIR_CVAR_CH4_OFI_ENABLE_RMA=0
echo "Running on $SLURM_N8 nodes with $SLURM_NTASKS tasks."

module list

bin_dir=/lus/bnchlu1/shanks/EPIC/310325/parcel-clustering/build_cce/bin
PATH=${bin_dir}:$PATH

rm /tmp/benchmark_random

EXE=${bin_dir}/benchmark_random

#sbcast --compress=none ${bin_dir}/benchmark_random /tmp/benchmark_random
for i in $(seq 1 10); do
    srun -v --nodes=8 \
        --ntasks=512 \
        --unbuffered \
        --distribution=block:block \
	--hint=nomultithread \
        ${EXE} \
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
        --csvfname "hotlum-cray-shmem-random-nx-256-ny-512-nz-32-nodes-8" \
        --comm-type "shmem"
    for g in "p2p" "rma"; do
        srun --nodes=8 \
            --ntasks=512 \
            --unbuffered \
            --distribution=block:block \
            --hint=nomultithread \
            ${EXE} \
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
            --csvfname "hotlum-cray-$g-random-nx-256-ny-512-nz-32-nodes-8" \
            --comm-type "$g"

        if test "false" = "true"; then
            srun --nodes=8 \
                --ntasks=512 \
                --unbuffered \
                --distribution=block:block \
                --hint=nomultithread \
                ${EXE} \
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
                --csvfname "hotlum-cray-$g-random-nx-256-ny-512-nz-32-nodes-8-subcomm" \
                --comm-type "$g" \
                --subcomm
        fi
    done
done

