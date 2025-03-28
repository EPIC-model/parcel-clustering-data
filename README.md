# Performance and scalability benchmarks of the parcel clustering algorithm

## Random benchmark
### ARCHER2
```
bash run_random.sh -m archer2 -l 128 -j 2 -u 1024 -r 10 -i 10 -f 0.5 -x 256 -y 512 -z 32 -a 80.0 -b 160.0 -c 10.0
bash run_random.sh -m archer2 -l 256 -j 2 -u 4096 -r 10 -i 10 -f 0.5 -x 512 -y 512 -z 32 -a 160.0 -b 160.0 -c 10.0
bash run_random.sh -m archer2 -l 1024 -j 2 -u 16384 -r 10 -i 10 -f 0.5 -x 1024 -y 1024 -z 32 -a 320.0 -b 320.0 -c 10.0
```

## Read benchmark
### ARCHER2
```
bash run_read.sh -m archer2 -l 128 -j 2 -u 1024 -r 10 -i 10 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-64x64x64/early-time/epic_rt_64x64x64_early -o 1 -n 10 -s -f 1.5
bash run_read.sh -m archer2 -l 128 -j 2 -u 1024 -r 10 -i 10 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-64x64x64/late-time/epic_rt_64x64x64_late -o 1 -n 10 -s -f 1.5
bash run_read.sh -m archer2 -l 256 -j 2 -u 4096 -r 10 -i 10 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-128x128x128/early-time/epic_rt_128x128x128_early -o 1 -n 10 -s -f 1.5
bash run_read.sh -m archer2 -l 256 -j 2 -u 4096 -r 10 -i 10 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-128x128x128/late-time/epic_rt_128x128x128_late -o 1 -n 10 -s -f 1.5
bash run_read.sh -m archer2 -l 1024 -j 2 -u 16384 -r 10 -i 10 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-256x256x256/early-time/epic_rt_256x256x256_early -o 1 -n 10 -s -f 1.5
bash run_read.sh -m archer2 -l 1024 -j 2 -u 16384 -r 10 -i 10 -b /work/e710/e710/mf248/parcel-clustering/scripts/rayleigh_taylor/rt-256x256x256/late-time/epic_rt_256x256x256_late -o 1 -n 10 -s -f 1.5
```
