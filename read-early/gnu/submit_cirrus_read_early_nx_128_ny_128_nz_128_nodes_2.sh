#!/bin/bash
#SBATCH --job-name=cirrus-gnu-read
#SBATCH --output=%x.o%j
#SBATCH --time=01:30:00
#SBATCH --nodes=2
#SBATCH --tasks-per-node=36
#SBATCH --cpus-per-task=1
#SBATCH --switches=1
#SBATCH --account=e710
#SBATCH --partition=standard
#SBATCH --qos=standard # largescale
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

if test "gnu" = "gnu"; then
    echo "Loading the GNU Compiler Collection (GCC)"
    module load libtool/2.4.7
    module load gcc/10.2.0
    module load openmpi/4.1.6
    module load hdf5parallel/1.14.3-gcc10-ompi416
    export NETCDF_C_DIR=/work/e710/e710/mf248/gcc-10.2.0-openmpi-4.1.6/netcdf
    export PATH=$PATH:$NETCDF_C_DIR/bin
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$NETCDF_C_DIR/lib
else
    echo "Only GNU Compiler Collection available!"
    exit 1
fi

echo "Setting SHMEM symmetric size"
export SHMEM_SYMMETRIC_SIZE=1G
export SHMEM_VERSION_DISPLAY=0
export SHMEM_ENV_DISPLAY=0

echo "Running on $SLURM_N2 nodes with $SLURM_NTASKS tasks."

module list

bin_dir=/work/e710/e710/mf248/gnu/bin
PATH=${bin_dir}:$PATH

for i in $(seq 1 5); do
    srun --kill-on-bad-exit \
         --nodes=2 \
         --ntasks=72 \
         --unbuffered \
         --distribution=block:block \
         ${bin_dir}/benchmark_read \
         --dirname /work/e710/e710/mf248/parcel-clustering-data/rayleigh_taylor/rt-128x128x128/early-time \
         --ncbasename epic_rt_128x128x128_early \
         --niter 100 \
         --offset 1 \
         --nfiles 10 \
         --size-factor 1.5 \
         --csvfname "cirrus-gnu-shmem-read-early-nx-128-ny-128-nz-128-nodes-2" \
         --comm-type "shmem"
    for g in "p2p" "rma"; do
        srun --kill-on-bad-exit \
             --nodes=2 \
             --ntasks=72 \
             --unbuffered \
             --distribution=block:block \
             --hint=nomultithread \
             ${bin_dir}/benchmark_read \
             --dirname /work/e710/e710/mf248/parcel-clustering-data/rayleigh_taylor/rt-128x128x128/early-time \
             --ncbasename epic_rt_128x128x128_early \
             --niter 100 \
             --offset 1 \
             --nfiles 10 \
             --size-factor 1.5 \
             --csvfname "cirrus-gnu-$g-read-early-nx-128-ny-128-nz-128-nodes-2" \
             --comm-type "$g"

        if test "true" = "true"; then
            srun --kill-on-bad-exit \
                 --nodes=2 \
                 --ntasks=72 \
                 --unbuffered \
                 --distribution=block:block \
                 --hint=nomultithread \
                 ${bin_dir}/benchmark_read \
                 --dirname /work/e710/e710/mf248/parcel-clustering-data/rayleigh_taylor/rt-128x128x128/early-time \
                 --ncbasename epic_rt_128x128x128_early \
                 --niter 100 \
                 --offset 1 \
                 --nfiles 10 \
                 --size-factor 1.5 \
                 --csvfname "cirrus-gnu-$g-read-early-nx-128-ny-128-nz-128-nodes-2-subcomm" \
                 --comm-type "$g" \
                 --subcomm
        fi
    done
done

