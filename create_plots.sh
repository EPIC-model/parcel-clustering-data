#!/bin/bash

python pytools/plot_osu.py --enable-latex --dirname osu/ --plot-type "bandwidth-put"
python pytools/plot_osu.py --enable-latex --dirname osu/ --plot-type "bandwidth-get"
python pytools/plot_osu.py --enable-latex --dirname osu/ --plot-type "latency-put"
python pytools/plot_osu.py --enable-latex --dirname osu/ --plot-type "latency-get"
