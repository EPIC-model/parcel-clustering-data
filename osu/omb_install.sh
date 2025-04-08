#!/bin/bash

# recipe for OSU Micro-Benchmarks (OMB):
OMB_VERSION=7.5-1
OMB=osu-micro-benchmarks

mkdir -p "$DOWNLOADS_DIR"
mkdir -p "$PREFIX"

# download OMB:
if [ ! -f "${DOWNLOADS_DIR}/$OMB-$OMB_VERSION.tar.gz" ]; then
    curl -L \
        --output "${DOWNLOADS_DIR}/$OMB-$OMB_VERSION.tar.gz" \
        "https://mvapich.cse.ohio-state.edu/download/mvapich/$OMB-$OMB_VERSION.tar.gz"
fi

# unpack
mkdir -p "${SRC_DIR}/$OMB" && cd "$_"
tar xvf "${DOWNLOADS_DIR}/$OMB-$OMB_VERSION.tar.gz"


# disable UPC
sed -i -e 's/upc_compiler=true/upc_compiler=false/g' ${SRC_DIR}/$OMB/$OMB-$OMB_VERSION/configure

# configure
mkdir -p "${SRC_DIR}/$OMB/build" && cd "$_"

if test "$(which cc > /dev/null 2>&1)" && \
   test "$(which CC > /dev/null 2>&1)" && \
   test "$(which ftn > /dev/null 2>&1)"; then
    
    ${SRC_DIR}/$OMB/$OMB-$OMB_VERSION/configure   \
        CXX=CC CC=cc FC=ftn \
        --prefix=${PREFIX}
else
    echo "Did not find CC, cc and ftn wrappers. Using mpic++, mpicc and mpifort."
    ${SRC_DIR}/$OMB/$OMB-$OMB_VERSION/configure   \
	CXX=mpic++ CC=mpicc FC=mpifort \
	LDFLAGS=$LDFLAGS \
	--prefix=${PREFIX}
fi

# compile & install
make -j ${NJOBS}
make install
