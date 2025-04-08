#!/bin/bash

run_jobs() {

    local machine=${1}
    local fname="submit_${machine}_osu.sh"

    local prefix=${2}

    echo "--------------------------------"
    echo "Run jobs with following options:"
    echo "machine               = $machine"
    echo "install_dir           = $prefix"
    echo "--------------------------------"

    mkdir -p -v "$machine-osu"
    cd "$machine-osu"
    fn="submit_${machine}_osu.sh"

    cp "../$fname" $fn
    sed -i "s:JOBNAME:$machine-osu:g" $fn
    sed -i "s:MACHINE:$machine:g" $fn

    sed -i "s:NTASKS:$ntasks:g" $fn
    sed -i "s:INSTALL_DIR:$prefix:g" $fn

    sbatch $fn

    cd ..
}

print_help() {
    echo "Script to submit OSU Micro Benchmarks"
    echo "Arguments:"
    echo "    -m    machine to run on, e.g. 'cirrus', 'archer2', 'hotlum'"
    echo "          (requirement: <machine>.sh and 'submit_<machine>_osu.sh)"
    echo "    -i    install directory of OSU Micro Benchmarks"
    echo "    -h    print this help message"
}

machine=''

while getopts "h?m:i:" option; do
    case "$option" in
        h|\?)
            print_help
            exit 0
            ;;
        i)
            install_dir=$OPTARG
            ;;
    	m)
            machine=$OPTARG
      	    ;;
    esac
done

if ! test -f "submit_${machine}_osu.sh" ; then
    echo "Unable to run on $machine. The file submit_${machine}_osu.sh does not exist. Exiting."
    exit 1
fi

run_jobs $machine "$install_dir"
