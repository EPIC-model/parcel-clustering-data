import matplotlib.pyplot as plt
import numpy as np
import os
import argparse
from matplotlib.legend_handler import HandlerTuple

try:

    # -------------------------------
    # Global settings:
    #

    plt.rcParams['font.family'] = 'serif'
    plt.rcParams['font.size'] = 15

    linestyles = ['solid', 'dashed']
    colors = ['tab:blue', 'tab:orange', 'tab:green']
    markers = ['o', 's', 'D']

    networks = {
        'archer2': r'SS10 (intra-/inter-node)',
        'hotlum':  r'SS11 (intra-/inter-node)',
        'cirrus':  r'IB (intra-/inter-node)'
    }

    osu_tests = {
        'osu_allreduce':            r'MPI Allreduce Latency Test',
        'osu_bw':                   r'MPI Bandwidth Test',
        'osu_get_bw_flush':         r'MPI-3 RMA Get (flush) Bandwidth Test',
        'osu_get_bw_lock':          r'MPI-3 RMA Get (lock/unlock) Bandwidth Test',
        'osu_get_latency_flush':    r'MPI-3 RMA Get (flush) Latency Test',
        'osu_get_latency_lock':     r'MPI-3 RMA Get (lock/unlock) Latency Test',
        'osu_latency':              r'MPI Latency Test',
        'osu_oshm_barrier':         r'OpenSHMEM Barrier Latency Test',
        'osu_oshm_get':             r'OpenSHMEM Get Latency Test',
        'osu_oshm_get_bw':          r'OpenSHMEM Get Bandwidth Test',
        'osu_oshm_put':             r'OpenSHMEM Put Latency Test',
        'osu_oshm_put_bw':          r'OpenSHMEM Put Bandwidth Test',
        'osu_put_bw_flush':         r'MPI-3 RMA Put (flush) Bandwidth Test',
        'osu_put_bw_lock':          r'MPI-3 RMA Put (lock/unlock) Bandwidth Test',
        'osu_put_latency_flush':    r'MPI-3 RMA Put (flush) Latency Test',
        'osu_put_latency_lock':     r'MPI-3 RMA Put (lock/unlock) Latency Test'
    }

    plot_types = {
        'bandwidth-put':    ['osu_oshm_put_bw', 'osu_put_bw_lock', 'osu_put_bw_flush'],
        'bandwidth-get':    ['osu_oshm_get_bw', 'osu_get_bw_lock', 'osu_get_bw_flush'],
        'latency-put':      ['osu_oshm_put', 'osu_put_latency_lock', 'osu_put_latency_flush'],
        'latency-get':      ['osu_oshm_get', 'osu_get_latency_lock', 'osu_get_latency_flush']
    }

    linewidth=1
    markersize=4


    # -------------------------------

    def plot_bandwidth(ax, dset, **kwargs):
        sizes = dset[:, 0]
        bw = dset[:, 1]


        ax.plot(sizes, bw, **kwargs)
        ax.set_xscale('log', base=10)
        ax.set_yscale('log', base=10)
        ax.set_xlabel(r'message size (B)')
        ax.set_ylabel(r'bandwidth (MB/s)')

    def plot_latency(ax, dset, **kwargs):
        sizes = dset[:, 0]
        lat = dset[:, 1]

        ax.plot(sizes, lat, **kwargs)
        ax.set_xscale('log', base=10)
        ax.set_yscale('log', base=10)
        ax.set_xlabel(r'message size (B)')

        enabled_latex = plt.rcParams['text.usetex']

        if enabled_latex:
            ax.set_ylabel(r'latency ($\mu$s)')
        else:
            ax.set_ylabel(r'latency (us)')


    def make_plot(ax, osu_test, machines, dirname):
        #comm_type = {
            #'1': r'(intra-node)',
            #'2': r'(inter-node)'
        #}

        for j, machine in enumerate(machines):
            for i, node in enumerate(['1', '2']):
                directory = os.path.join(dirname, machine + '-osu-runs')
                fname = os.path.join(directory, machine + '-nodes-' + node + '-' + osu_test)

                dset = np.loadtxt(fname=fname, comments='#')

                is_scalar = (dset.shape == ())

                label = None

                if is_scalar:
                    print("Not plotting.")
                else:
                    if 'bw' in osu_test:
                        plot_bandwidth(ax,
                                       dset,
                                       label=networks[machine], # + ' ' + comm_type[node],
                                       linestyle=linestyles[i],
                                       color=colors[j],
                                       marker=markers[j],
                                       markersize=markersize,
                                       linewidth=linewidth)
                    else:
                        plot_latency(ax,
                                     dset,
                                     label=networks[machine], # + ' ' + comm_type[node],
                                     linestyle=linestyles[i],
                                     color=colors[j],
                                     marker=markers[j],
                                     markersize=markersize,
                                     linewidth=linewidth)


    parser = argparse.ArgumentParser(
            description="Generate OSU micro benchmark plot."
    )

    parser.add_argument(
        "--plot-type",
        type=str,
        default="",
        choices=plot_types.keys(),
        help="OSU micro benchmark test",
    )

    parser.add_argument(
        "--machines",
        type=str,
        nargs='+',
        default=['archer2', 'hotlum', 'cirrus'],
        help="Computing systems",
    )

    parser.add_argument(
        "--dirname",
        type=str,
        default=".",
        help="Root directory of OSU micro benchmark data."
    )

    parser.add_argument(
        "--enable-latex",
        action='store_true',
        help="Use LateX for plot labels."
    )


    args = parser.parse_args()

    plt.rcParams['text.usetex'] = args.enable_latex

    plot_type = plot_types[args.plot_type]

    n = len(plot_type)

    fig, axs = plt.subplots(nrows=1, ncols=n, sharey=True, figsize=(5*n, 5), dpi=200)

    for i, osu_test in enumerate(plot_type):
        make_plot(axs[i], osu_test, args.machines, args.dirname)
        axs[i].set_title(osu_tests[osu_test])
        axs[i].grid(which='both', zorder=-10, linestyle='dashed', linewidth=0.4)

        loc = 'lower right'
        if 'latency' in args.plot_type:
            loc='upper left'

        handles, labels = axs[i].get_legend_handles_labels()
        axs[i].legend(loc=loc, ncols=1,
                      handles=[[handles[0], handles[1]],
                               [handles[2], handles[3]],
                               [handles[4], handles[5]]],
                      labels=[networks[args.machines[0]],
                              networks[args.machines[1]],
                              networks[args.machines[2]]],
                      handlelength=3,
                      handler_map={list: HandlerTuple(ndivide=None)})

        if i > 0:
            axs[i].set_ylabel(None)

    plt.tight_layout()

    plt.savefig('osu-' + args.plot_type + '.pdf', bbox_inches='tight')
    plt.close()


except Exception as ex:
    print(ex, flush=True)
