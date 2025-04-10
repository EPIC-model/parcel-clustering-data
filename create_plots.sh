#!/bin/bash

print_help() {
    echo "Script to run plotting scripts."
    echo "Arguments:"
    echo "    -w    what to plot, choices: 'random', 'read-early', 'read-late', 'osu', 'all'"
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
fi

for benchmark in "random" "read-early" "read-late"; do
    if test "$what_to_plot" == "all" || test "$what_to_plot" == "$benchmark"; then
        python pytools/plot_scaling.py --compiler-suite cray \
                                       $enable_latex \
                                       --test-case "$benchmark" \
                                       --figure single \
                                       --path ./ \
                                       --plot weak-strong-scaling \
                                       --output-dir figures
    fi
done
