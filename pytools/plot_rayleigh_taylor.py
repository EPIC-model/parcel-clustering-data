import numpy as np
import matplotlib.pyplot as plt
import argparse
import os
import re
import netCDF4 as nc
from matplotlib.legend_handler import HandlerTuple


try:

    plt.rcParams['font.family'] = 'sans'
    plt.rcParams['font.size'] = 13
    plt.rcParams['lines.linewidth'] = 2


    def plot_parcel_statistics(args):
        dirnames = ['rt-64x64x64', 'rt-128x128x128', 'rt-256x256x256']

        main_labels = []
        pattern = r'rt-(\d*)x(\d*)x(\d*)'
        for dirname in dirnames:
            m = re.match(pattern, dirname)
            if args.enable_latex:
                main_labels.append(r'$' + m.group(1) + r'\times ' + m.group(2) + r'\times ' + m.group(3) + r'$')
            else:
                main_labels.append(m.group(1) + r' x ' + m.group(2) + ' x ' + m.group(3))

        fig, axs = plt.subplots(nrows=1, ncols=3, figsize=(4.5*3, 4.25), dpi=400, sharex=True)

        handles = []
        labels = []

        for i, dirname in enumerate(dirnames):
            fullpath = os.path.join(args.path, dirname)
            if not os.path.exists(fullpath):
                raise RuntimeError("Directory '" + fullpath + "' does not exist.")

            s = dirname.replace('-', '_')
            data = np.loadtxt(fname=os.path.join(fullpath, 'epic_' + s + '_prepare_nearest_subcomm.asc'),
                            comments='#')

            time = data[:, 0]
            size = data[:, 1]
            percentage = data[:, 2]


            ncfile = nc.Dataset(os.path.join(fullpath, 'epic_' + s + '_prepare_parcel_stats.nc'),
                                "r", format="NETCDF4")

            n_small_parcels = np.array(ncfile.variables['n_small_parcel'])
            n_total_parcels = np.array(ncfile.variables['n_parcels'])

            t = np.array(ncfile.variables['t'])
            ncfile.close()

            h1, = axs[0].plot(t, n_total_parcels, color=cmap(i), linestyle='dashed')
            h2, = axs[0].plot(t, n_small_parcels, color=cmap(i))
            handles.append(h1)
            handles.append(h2)

            axs[0].set_yscale('log', base=10)

            axs[1].plot(t, n_small_parcels / n_total_parcels * 100.0, color=cmap(i), label=main_labels[i])
            axs[2].plot(time, percentage, color=cmap(i))

        for i in range(3):
            axs[i].set_xlim([2.5, None])
            axs[i].grid(which='both', zorder=10, linestyle='dashed', linewidth=0.25)
            axs[i].set_xlabel(r'simulation time')

        fig.legend(loc='upper center', ncols=len(main_labels), bbox_to_anchor=(0.5, 1.07))

        axs[0].set_ylabel(r'number of parcels')

        axs[0].legend(loc='lower right',
                    handles=[(handles[0], handles[2], handles[4]),
                            (handles[1], handles[3], handles[5])],
                    labels=['total parcels', 'small parcels'],
                    ncols=1,
                    handlelength=4.5,
                    columnspacing=0.8,
                    handler_map={tuple: HandlerTuple(ndivide=None)})

        if args.enable_latex:
            axs[1].set_ylabel(r'fraction of small parcels (\%)')
            axs[2].set_ylabel(r'MPI sub-communicator size (\%)')
        else:
            axs[1].set_ylabel(r'fraction of small parcels (%)')
            axs[2].set_ylabel(r'MPI sub-communicator size (%)')


        plt.tight_layout()
        plt.savefig(os.path.join(args.output_dir, 'rt_subcomm.pdf'), bbox_inches='tight')
        plt.close()


    def plot_merger_statistics(args):

        dirname = 'rt-256x256x256'

        fullpath = os.path.join(args.path, dirname)
        if not os.path.exists(fullpath):
            raise RuntimeError("Directory '" + fullpath + "' does not exist.")

        s = dirname.replace('-', '_')
        ncfile = nc.Dataset(os.path.join(fullpath, 'epic_' + s + '_prepare_parcel_stats.nc'),
                                "r", format="NETCDF4")

        n_parcel_merges = np.array(ncfile.variables['n_parcel_merges'])
        n_big_neighbour = np.array(ncfile.variables['n_big_neighbour'])
        n_way_merging = np.array(ncfile.variables['n_way_merging'])
        t = np.array(ncfile.variables['t'])
        ncfile.close()

        fig, axs = plt.subplots(nrows=1, ncols=2, figsize=(4.5*2, 4.25), dpi=400)


        total = n_way_merging.sum(axis=(0,1))

        # -1 because we do not have any 8-way mergers
        for i in range(n_way_merging.shape[1]-1):
            axs[0].plot(t, np.cumsum(n_way_merging[:, i]), label=str(i+2) + '-way')

            percent = n_way_merging[:, i].sum() / total * 100.0
            print(str(i+2) + '-way mergers:', round(percent, 8), '%')
            axs[1].bar(i, percent)

        axs[0].set_xlim([2.5, None])
        axs[0].set_xlabel(r'simulation time')
        axs[0].set_yscale('log', base=10)
        axs[0].set_ylabel(r'cumulative sum of $n$-way mergers')
        axs[0].legend(loc='upper center', ncols=3, bbox_to_anchor=(0.5, 1.25))

        axs[1].set_yscale('log', base=10)
        axs[1].set_xticks([0, 1, 2, 3, 4, 5])
        axs[1].set_xticklabels(['2-way', '3-way', '4-way', '5-way', '6-way', '7-way'])
        axs[1].set_ylabel(r'fraction of $n$-way mergers (\%)')

        for i in range(2):
            axs[i].grid(which='both', zorder=10, linestyle='dashed', linewidth=0.25)

        plt.tight_layout()
        plt.savefig(os.path.join(args.output_dir, 'rt_mergers.pdf'), bbox_inches='tight')
        plt.close()


    parser = argparse.ArgumentParser(
            description="Generate Rayleigh-Taylor plots."
    )

    parser.add_argument(
        "--path",
        type=str,
        default='rayleigh_taylor',
        help="Data directory.",
    )

    parser.add_argument(
        "--colour-map",
        type=str,
        default='tab10',
        help="Colour map for plotting."
    )

    parser.add_argument(
        "--enable-latex",
        action='store_true',
        help="Use LateX for plot labels."
    )

    parser.add_argument(
        "--output-dir",
        type=str,
        default=".",
        help="Figure save directory."
    )

    args = parser.parse_args()

    cmap = plt.get_cmap(args.colour_map)

    plt.rcParams['text.usetex'] = args.enable_latex


    plot_parcel_statistics(args)

    plot_merger_statistics(args)


except Exception as ex:
    print(ex, flush=True)
