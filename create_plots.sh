#!/bin/bash

print_help() {
    echo "Script to run plotting scripts."
    echo "Arguments:"
    echo "    -w    what to plot,"
    echo "          choices: 'random', 'read-early', 'read-late', 'osu', 'rayleigh-taylor' or 'all'"
    echo "    -h    print this help message"
}

what_to_plot="all"

while getopts "h?w:" option; do
    case "$option" in
        h|\?)
            print_help
            exit 0
            ;;
        w)
            what_to_plot=$OPTARG
            ;;
    esac
done

if ! test "$(which python)" >/dev/null 2>&1; then
    echo "Error: No python found."
    exit 1
fi

enable_latex=""
if test "$(which pdflatex)" >/dev/null 2>&1; then
    enable_latex="--enable-latex"
    echo "Found LaTeX installation. Enabling LaTeX fonts."
fi

mkdir -p -v "figures"

if test "$what_to_plot" == "all" || test "$what_to_plot" == "osu"; then
    python pytools/plot_osu.py $enable_latex --dirname osu/ --plot-type bandwidth-put --output-dir figures
    python pytools/plot_osu.py $enable_latex --dirname osu/ --plot-type bandwidth-get --output-dir figures
    python pytools/plot_osu.py $enable_latex --dirname osu/ --plot-type latency-put --output-dir figures
    python pytools/plot_osu.py $enable_latex --dirname osu/ --plot-type latency-get --output-dir figures
    python pytools/plot_osu.py $enable_latex --dirname osu/ --plot-type mpi-p2p --output-dir figures
fi

for benchmark in "random" "read-early" "read-late"; do
    if test "$benchmark" == "random"; then
        nruns=10
    else
        nruns=5
    fi
    if test "$what_to_plot" == "all" || test "$what_to_plot" == "$benchmark"; then
        for s in "" "--use-subcomm"; do
            python pytools/plot_scaling.py --compiler-suites 'cray' 'gnu' \
                                           $enable_latex $s \
                                           --test-case "$benchmark" \
                                           --path ./ \
                                           --plot weak-strong-scaling \
                                           --output-dir figures \
                                           --nruns $nruns
        done
    fi
done

if test "$what_to_plot" == "all" || test "$what_to_plot" == "rayleigh-taylor"; then
    python pytools/plot_rayleigh_taylor.py  --path rayleigh_taylor \
                                            --output-dir figures $enable_latex
fi
