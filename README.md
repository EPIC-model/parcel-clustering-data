# Performance and scalability benchmarks of the parcel clustering algorithm

## Installation
Please visit https://github.com/EPIC-model/parcel-clustering for general installation instructions.
* [Installation on ARCHER2](ARCHER2.md)
* [Installation on Cirrus](Cirrus.md)
* [Installation on Hotlum](Hotlum.md)


## How to run the verification benchmark
In order to run the code verification benchmark you need to add two machine-specific files
to the directory [scripts/benchmark_verify](https://github.com/EPIC-model/parcel-clustering/tree/update-doc/scripts/benchmark_verify) directory:

* `<machine>.sh`
* `submit_<machine>_verify.sh`

where `<machine>` is the name of the computing system (or any arbitrary name). As an example of a submission script see [submit_archer2_verify.sh](scripts/benchmark_verify/submit_archer2_verify.sh).
For the verification benchmark, the submission script must specify the following placeholders:

| placeholder | description                               |
| ----------- | ----------------------------------------- |
| COMPILER    | name of the compiler suite, e.g. cce, gnu |
| COMM_TYPE   | communication layer, e.g. shmem, p2p, rma |
| N_SAMPLES   | number of random samples                  |
| SEED        | seed for the random sample generator      |
| BIN_DIR     | bin directory of the executable           |

The file `<machine.sh>` must contain the variable `ntasks_per_node` and two arrays
`bins` and `compilers` that specify the location of the executables and the name of the compiler suite, respectively.
As an example consult [archer2.sh](scripts/archer2.sh). Once these files are specified the verification benchmark can be
started within the directory [scripts/benchmark_verify](scripts/benchmark_verify) using the following command
```bash
bash run_verify.sh -m [machine] -s [seed] -n [number of samples] -c [communication layer]
```
where the tags within square brackets must be specified. You may also run `bash run_verify.sh -h` to get further information.


## How to run the random sample scaling benchmark
Similarly to the verification benchmark, the random sample scaling benchmark requires two files

* `<machine>.sh`
* `submit_<machine>_random.sh`

Different to the verification benchmark, the submission script `submit_<machine>_random.sh` now specifies the following
placeholders:

| placeholder | description                                        |
| ----------- | -------------------------------------------------- |
| COMPILER    | name of the compiler suite, e.g. cce, gnu          |
| NREPEAT     | number of repetitions of the scaling study         |
| NODES       | number of random samples                           |
| NTASKS      | number of cores                                    |
| NITER       | number of iterations per repetition                |
| NX          | number of grid cells in the horizontal direction x |
| NY          | number of grid cells in the horizontal direction y |
| NZ          | number of grid cells in the vertical direction z   |
| LX          | domain extent in the horizontal direction x        |
| LY          | domain extent in the horizontal direction y        |
| LZ          | domain extent in the vertical direction z          |
| BIN_DIR     | bin directory of the executable                    |
| SUBCOMM     | if a sub-communicator should be used (optional)    |

An example is provided with [submit_archer2_random.sh](scripts/benchmark_random/submit_archer2_random.sh).

A scaling study can be submitted within the directory [scripts/benchmark_random](scripts/benchmark_random) with
`run_random.sh`. For further information please run `bash run_random.sh -h`.



## Random benchmark
### Cirrus
```bash
bash run_random.sh -m cirrus -l 36 -j 2 -u 288 -r 10 -i 10 -f 0.5 -x 72 -y 144 -z 32 -a 22.5 -b 45.0 -c 10.0
bash run_random.sh -m cirrus -l 36 -j 2 -u 288 -r 10 -i 10 -f 0.5 -x 144 -y 288 -z 32 -a 45.0 -b 90.0 -c 10.0
bash run_random.sh -m cirrus -l 72 -j 2 -u 1152 -r 10 -i 10 -f 0.5 -x 288 -y 288 -z 32 -a 90.0 -b 90.0 -c 10.0
bash run_random.sh -m cirrus -l 288 -j 2 -u 4608 -r 10 -i 10 -f 0.5 -x 576 -y 576 -z 32 -a 180.0 -b 180.0 -c 10.0
```

### ARCHER2
```
bash run_random.sh -m archer2 -l 128 -j 2 -u 1024 -r 10 -i 10 -f 0.5 -x 256 -y 512 -z 32 -a 80.0 -b 160.0 -c 10.0
bash run_random.sh -m archer2 -l 256 -j 2 -u 4096 -r 10 -i 10 -f 0.5 -x 512 -y 512 -z 32 -a 160.0 -b 160.0 -c 10.0
bash run_random.sh -m archer2 -l 1024 -j 2 -u 16384 -r 10 -i 10 -f 0.5 -x 1024 -y 1024 -z 32 -a 320.0 -b 320.0 -c 10.0
```

## Read benchmark
### ARCHER2
```
bash run_read.sh -m archer2 -l 64 -j 2 -u 512 -r 5 -i 100 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-64x64x64/early-time/epic_rt_64x64x64_early -o 1 -n 10 -s -f 1.5
bash run_read.sh -m archer2 -l 128 -j 2 -u 2048 -r 5 -i 100 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-128x128x128/early-time/epic_rt_128x128x128_early -o 1 -n 10 -s -f 1.5
bash run_read.sh -m archer2 -l 512 -j 2 -u 1024 -r 5 -i 100 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-256x256x256/early-time/epic_rt_256x256x256_early -o 1 -n 10 -s -f 1.5
bash run_read.sh -m archer2 -l 2048 -j 2 -u 2048 -r 5 -i 100 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-256x256x256/early-time/epic_rt_256x256x256_early -o 1 -n 10 -s -f 2.0
bash run_read.sh -m archer2 -l 4096 -j 2 -u 4096 -r 5 -i 100 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-256x256x256/early-time/epic_rt_256x256x256_early -o 1 -n 10 -s -f 3.0
bash run_read.sh -m archer2 -l 8192 -j 2 -u 8192 -r 5 -i 100 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-256x256x256/early-time/epic_rt_256x256x256_early -o 1 -n 10 -s -f 4.0


bash run_read.sh -m archer2 -l 64 -j 2 -u 512 -r 5 -i 100 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-64x64x64/late-time/epic_rt_64x64x64_late -o 1 -n 10 -s -f 1.5
bash run_read.sh -m archer2 -l 128 -j 2 -u 2048 -r 5 -i 100 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-128x128x128/late-time/epic_rt_128x128x128_late -o 1 -n 10 -s -f 1.5
bash run_read.sh -m archer2 -l 512 -j 2 -u 1024 -r 5 -i 100 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-256x256x256/late-time/epic_rt_256x256x256_late -o 1 -n 10 -s -f 1.5
bash run_read.sh -m archer2 -l 2048 -j 2 -u 2048 -r 5 -i 100 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-256x256x256/late-time/epic_rt_256x256x256_late -o 1 -n 10 -s -f 2.0
bash run_read.sh -m archer2 -l 4096 -j 2 -u 4096 -r 5 -i 100 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-256x256x256/late-time/epic_rt_256x256x256_late -o 1 -n 10 -s -f 3.0
bash run_read.sh -m archer2 -l 8192 -j 2 -u 8192 -r 5 -i 100 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-256x256x256/late-time/epic_rt_256x256x256_late -o 1 -n 10 -s -f 4.0
```

### Hotlum
```
bash run_read.sh -m hotlum -l 64 -j 2 -u 512 -r 5 -i 100 -b /lus/bnchlu1/shanks/EPIC/data/rt-64x64x64/early-time/epic_rt_64x64x64_early -o 1 -n 10 -s -f 1.5
bash run_read.sh -m hotlum -l 128 -j 2 -u 2048 -r 5 -i 100 -b /lus/bnchlu1/shanks/EPIC/data/rt-128x128x128/early-time/epic_rt_128x128x128_early -o 1 -n 10 -s -f 1.5
bash run_read.sh -m hotlum -l 512 -j 2 -u 1024 -r 5 -i 100 -b /lus/bnchlu1/shanks/EPIC/data/rt-256x256x256/early-time/epic_rt_256x256x256_early -o 1 -n 10 -s -f 1.5
bash run_read.sh -m hotlum -l 2048 -j 2 -u 2048 -r 5 -i 100 -b /lus/bnchlu1/shanks/EPIC/data/rt-256x256x256/early-time/epic_rt_256x256x256_early -o 1 -n 10 -s -f 2.0
bash run_read.sh -m hotlum -l 4096 -j 2 -u 4096 -r 5 -i 100 -b /lus/bnchlu1/shanks/EPIC/data/rt-256x256x256/early-time/epic_rt_256x256x256_early -o 1 -n 10 -s -f 3.0
bash run_read.sh -m hotlum -l 8192 -j 2 -u 8192 -r 5 -i 100 -b /lus/bnchlu1/shanks/EPIC/data/rt-256x256x256/early-time/epic_rt_256x256x256_early -o 1 -n 10 -s -f 4.0


bash run_read.sh -m hotlum -l 64 -j 2 -u 512 -r 5 -i 100 -b /lus/bnchlu1/shanks/EPIC/data/rt-64x64x64/late-time/epic_rt_64x64x64_late -o 1 -n 10 -s -f 1.5
bash run_read.sh -m hotlum -l 128 -j 2 -u 2048 -r 5 -i 100 -b /lus/bnchlu1/shanks/EPIC/data/rt-128x128x128/late-time/epic_rt_128x128x128_late -o 1 -n 10 -s -f 1.5
bash run_read.sh -m hotlum -l 512 -j 2 -u 1024 -r 5 -i 100 -b /lus/bnchlu1/shanks/EPIC/data/rt-256x256x256/late-time/epic_rt_256x256x256_late -o 1 -n 10 -s -f 1.5
bash run_read.sh -m hotlum -l 2048 -j 2 -u 2048 -r 5 -i 100 -b /lus/bnchlu1/shanks/EPIC/data/rt-256x256x256/late-time/epic_rt_256x256x256_late -o 1 -n 10 -s -f 2.0
bash run_read.sh -m hotlum -l 4096 -j 2 -u 4096 -r 5 -i 100 -b /lus/bnchlu1/shanks/EPIC/data/rt-256x256x256/late-time/epic_rt_256x256x256_late -o 1 -n 10 -s -f 3.0
bash run_read.sh -m hotlum -l 8192 -j 2 -u 8192 -r 5 -i 100 -b /lus/bnchlu1/shanks/EPIC/data/rt-256x256x256/late-time/epic_rt_256x256x256_late -o 1 -n 10 -s -f 4.0
```
