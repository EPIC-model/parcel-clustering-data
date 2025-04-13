#!/bin/bash

run_jobs() {

    local machine=${1}
    local fname="submit_${machine}_random.sh"
    local ntasks_per_node=${2}

    local compiler=${3}

    local bin_dir=${4}
    local nrepeat=${5}
    local niter=${6}
    local nx=${7}
    local ny=${8}
    local nz=${9}
    local lx=${10}
    local ly=${11}
    local lz=${12}
    local min_ntasks=${13}
    local inc_ntasks=${14}
    local max_ntasks=${15}
    local subcomm=${16}
    local ratio=${17}

    echo "--------------------------------"
    echo "Run jobs with following options:"
    echo "machine               = $machine"
    echo "ntasks_per_node       = $ntasks_per_node"
    echo "fname                 = $fname"
    echo "compiler              = $compiler"
    echo "bin_dir               = $bin_dir"
    echo "nrepeat               = $nrepeat"
    echo "niter                 = $niter"
    echo "small_parcel_fraction = $ratio"
    echo "nx                    = $nx"
    echo "ny                    = $ny"
    echo "nz                    = $nz"
    echo "lx                    = $lx"
    echo "ly                    = $ly"
    echo "lz                    = $lz"
    echo "min_ntasks            = $min_ntasks"
    echo "inc_ntasks            = $inc_ntasks"
    echo "max_ntasks            = $max_ntasks"
    if ! test "$subcomm" = "true"; then
        subcomm="false"
    fi
    echo "subcomm               = $subcomm"
    echo "--------------------------------"

    mkdir -p -v "random"
    cd "random"
    mkdir -p -v "$compiler"
    cd "$compiler"

    ntasks=$min_ntasks
    while (($ntasks <= $max_ntasks)); do
        nodes=$((ntasks/ntasks_per_node))

        # avoid nodes = 0
        if test $nodes = 0; then
            nodes=1
        fi

        echo "Submit job with $ntasks tasks on $nodes nodes using the $compiler version"

        fn="submit_${machine}_random_nx_${nx}_ny_${ny}_nz_${nz}_nodes_${nodes}.sh"

        cp "../../template/$fname" $fn
        sed -i "s:JOBNAME:$machine-$compiler-random:g" $fn
        sed -i "s:COMPILER:$compiler:g" $fn
        sed -i "s:MACHINE:$machine:g" $fn

        sed -i "s:NREPEAT:$nrepeat:g" $fn
        sed -i "s:NODES:$nodes:g" $fn
        sed -i "s:--ntasks=NTASKS:--ntasks=$ntasks:g" $fn
        sed -i "s:-np NTASKS:-np $ntasks:g" $fn
        sed -i "s:--niter NITER:--niter $niter:g" $fn
        sed -i "s:NX:$nx:g" $fn
        sed -i "s:NY:$ny:g" $fn
        sed -i "s:NZ:$nz:g" $fn

        sed -i "s:--lx LX:--lx $lx:g" $fn
        sed -i "s:--ly LY:--ly $ly:g" $fn
        sed -i "s:--lz LZ:--lz $lz:g" $fn
        sed -i "s:--small-parcel-fraction SMALL_PARCEL_FRACTION:--small-parcel-fraction $ratio:g" $fn

        sed -i "s:BIN_DIR:$bin_dir:g" $fn
        sed -i "s:SUBCOMM:$subcomm:g" $fn

        sbatch $fn

        ntasks=$((ntasks*inc_ntasks))
    done

    cd ../..
}

# Argument order of run_jobs
# machine
# ntasks_per_node
# compiler : cray or gnu
# bin_dir
# nrepeat
# niter
# nx
# ny
# nz
# lx
# ly
# lz
# min_ntasks
# inc_ntasks
# max_ntasks
# subcomm
# small_parcel_fraction

print_help() {
    echo "Script to submit strong / weak scaling jobs"
    echo "where the number of cores is doubled in each"
    echo "iteration from '-l' to '-u'"
    echo "Arguments:"
    echo "    -m    machine to run on, e.g. 'cirrus', 'archer2', 'hotlum'"
    echo "          (requirement: <machine>.sh and 'submit_<machine>_random.sh)"
    echo "    -h    print this help message"
    echo "    -l    lower bound of cores"
    echo "    -j    increment factor of cores"
    echo "    -u    upper bound of cores"
    echo "    -r    number of repetitions"
    echo "    -i    number of iterations per repetition"
    echo "    -f    fraction of small parcels [0, 1]"
    echo "    -x    number of grid cells in the horizontal direction x"
    echo "    -y    number of grid cells in the horizontal direction y"
    echo "    -z    number of grid cells in the vertical direction z"
    echo "    -a    domain extent in the horizontal direction x"
    echo "    -b    domain extent in the horizontal direction y"
    echo "    -c    domain extent in the vertical direction z"
    echo "    -s    use sub-communicator (optional)"
}

check_for_input() {
    if ! test "${2}"; then
        echo "Please specify '${1}'. Exiting."
	exit 1
    fi
}


machine=''

# default options:
subcomm="false"
inc_cores=2
nrep=1
niter=1

while getopts "h?m:l:u:j:r:f:i:x:y:z:a:b:c:s" option; do
    case "$option" in
        a)
            lx=$OPTARG
            ;;
        b)
            ly=$OPTARG
            ;;
        c)
            lz=$OPTARG
            ;;
        h|\?)
            print_help
            exit 0
            ;;
        f)
            small_parcel_fraction=$OPTARG
            ;;
        i)
            niter=$OPTARG
            ;;
        j)
            inc_cores=$OPTARG
            ;;
        l)
            min_cores=$OPTARG
            ;;
    	m)
            machine=$OPTARG
      	    ;;
        r)
            nrep=$OPTARG
            ;;
        s)
            subcomm="true"
            ;;
        u)
            max_cores=$OPTARG
            ;;
        x)
            nx=$OPTARG
            ;;
        y)
            ny=$OPTARG
            ;;
        z)
            nz=$OPTARG
            ;;
    esac
done

check_for_input "nrep" $nrep
check_for_input "niter" $niter
check_for_input "nx" $nx
check_for_input "ny" $ny
check_for_input "nz" $nz
check_for_input "lx" $lx
check_for_input "ly" $ly
check_for_input "lz" $lz
check_for_input "min_cores" $min_cores
check_for_input "inc_cores" $inc_cores
check_for_input "max_cores" $max_cores
check_for_input "subcomm" $subcomm
check_for_input "small_parcel_fraction", $small_parcel_fraction

if ! test -f "template/$machine.sh"; then
    echo "Unable to run on $machine. The file template/${machine}.sh does not exist. Exiting."
    exit 1
fi

if ! test -f "template/submit_${machine}_random.sh" ; then
    echo "Unable to run on $machine. The file template/submit_${machine}_random.sh does not exist. Exiting."
    exit 1
fi

# set bin directories
source "template/$machine.sh"

check_for_input "ntasks_per_node" $ntasks_per_node


echo "Submiting jobs on $machine with $min_cores to $max_cores cores."
echo "Each job is repeated $nrep times with $niter iterations per repetition."

j=0
for bin_dir in ${bins[*]}; do
    compiler="${compilers[$j]}"

    run_jobs $machine $ntasks_per_node $compiler "$bin_dir" $nrep $niter $nx $ny $nz $lx $ly $lz $min_cores $inc_cores $max_cores $subcomm $small_parcel_fraction

    j=$((j+1))
done
