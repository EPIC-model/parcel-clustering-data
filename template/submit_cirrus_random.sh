#!/bin/bash
#SBATCH --job-name=JOBNAME
#SBATCH --output=%x.o%j
#SBATCH --time=00:10:00
#SBATCH --nodes=NODES
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

if test "COMPILER" = "gnu"; then
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

echo "Running on $SLURM_NNODES nodes with $SLURM_NTASKS tasks."

module list

bin_dir=BIN_DIR
PATH=${bin_dir}:$PATH

for i in $(seq 1 NREPEAT); do
    srun --kill-on-bad-exit \
         --nodes=NODES \
         --ntasks=NTASKS \
         --unbuffered \
         --distribution=block:block \
         ${bin_dir}/benchmark_random \
         --nx NX \
         --ny NY \
         --nz NZ \
         --lx LX \
         --ly LY \
         --lz LZ \
         --min-vratio 20.0 \
         --nppc 20 \
         --niter NITER \
         --small-parcel-fraction SMALL_PARCEL_FRACTION \
         --shuffle \
         --csvfname "MACHINE-COMPILER-shmem-random-nx-NX-ny-NY-nz-NZ-nodes-NODES" \
         --comm-type "shmem"
    for g in "p2p" "rma"; do
        srun --kill-on-bad-exit \
	     --nodes=NODES \
             --ntasks=NTASKS \
             --unbuffered \
             --distribution=block:block \
             --hint=nomultithread \
             ${bin_dir}/benchmark_random \
             --nx NX \
             --ny NY \
             --nz NZ \
             --lx LX \
             --ly LY \
             --lz LZ \
             --min-vratio 20.0 \
             --nppc 20 \
             --niter NITER \
             --small-parcel-fraction SMALL_PARCEL_FRACTION \
             --shuffle \
             --csvfname "MACHINE-COMPILER-$g-random-nx-NX-ny-NY-nz-NZ-nodes-NODES" \
             --comm-type "$g"

        if test "SUBCOMM" = "true"; then
            srun --kill-on-bad-exit \
	         --nodes=NODES \
                 --ntasks=NTASKS \
                 --unbuffered \
                 --distribution=block:block \
                 --hint=nomultithread \
                 ${bin_dir}/benchmark_random \
                 --nx NX \
                 --ny NY \
                 --nz NZ \
                 --lx LX \
                 --ly LY \
                 --lz LZ \
                 --min-vratio 20.0 \
                 --nppc 20 \
                 --niter NITER \
                 --small-parcel-fraction SMALL_PARCEL_FRACTION \
                 --shuffle \
                 --csvfname "MACHINE-COMPILER-$g-random-nx-NX-ny-NY-nz-NZ-nodes-NODES-subcomm" \
                 --comm-type "$g" \
                 --subcomm
        fi
    done
done

