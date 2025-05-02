## Installation on Cirrus
Please also consult the [Cirrus documentation](https://docs.cirrus.ac.uk/user-guide/development/).

<!--### HPE MPT MPI with Intel compiler suite
```bash
module load libtool/2.4.7
module load mpt/2.25
module load intel-20.4/compilers
module load netcdf-parallel/4.9.2-intel20-mpt225
export NETCDF_FORTRAN_DIR=$NETCDF_DIR
export NETCDF_C_DIR=$NETCDF_DIR
export MPICC_CC=icc
export MPICXX_CXX=icpc
CXX="mpicxx -cxx=icpc -lsma" CC="mpicc -cc=icc -lsma" FC="mpif08 -fc=ifort -lsma" ../configure --prefix=$PREFIX
```-->

<!-- #### Intel MPI with Intel compiler suite
```bash
module load intel-20.4/mpi
module load intel-20.4/compilers
module load netcdf-parallel/4.9.2-intel20-impi20
export NETCDF_C_DIR=$NETCDF_DIR
export NETCDF_FORTRAN_DIR=$NETCDF_DIR
CXX=mpiicpc CC=mpiicc FC=mpiifort ../configure
```
-->

### Open MPI with GNU compiler suite

That is the build with OpenMPI/4.1.6.
```bash
module load libtool/2.4.7
module load gcc/10.2.0
module load openmpi/4.1.6
module load hdf5parallel/1.14.3-gcc10-ompi416
export NETCDF_C_DIR=/work/e710/e710/mf248/gcc-10.2.0-openmpi-4.1.6/netcdf
export NETCDF_FORTRAN_DIR=/work/e710/e710/mf248/gcc-10.2.0-openmpi-4.1.6/netcdf
export PATH=$PATH:$NETCDF_C_DIR/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$NETCDF_C_DIR/lib
export CPLUS_INCLUDE_PATH=$NETCDF_C_DIR/include:$CPLUS_INCLUDE_PATH
export C_INCLUDE_PATH=$NETCDF_C_DIR/include:$C_INCLUDE_PATH
CC=mpicc CXX=mpic++ FC=mpifort ../configure --prefix=/work/e710/e710/mf248/gnu
```
