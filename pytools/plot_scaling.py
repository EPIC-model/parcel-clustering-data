import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import re
import argparse
from matplotlib.legend_handler import HandlerTuple


try:

    #
    # Global settings
    #
    plt.rcParams['font.family'] = 'sans'
    plt.rcParams['font.size'] = 12


    # :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    # Helper functions and classes for parsing and plotting the data:
    #
    class DataSet:

        def __init__(self, path, compiler_suites, test_case, use_subcomm = False):
            self.path = path
            self.use_subcomm = use_subcomm

            self.titles = {
                'p2p':   r'MPI P2P + MPI P2P',
                'rma':   r'MPI P2P + MPI-3 RMA',
                'shmem': r'MPI P2P + SHMEM'
            }

            self.ncalls_csv = "-ncalls.csv"
            self.timing_csv = "-timings.csv"
            if self.use_subcomm:
                self.timing_csv = "-subcomm" + self.timing_csv
                self.ncalls_csv = "-subcomm" + self.ncalls_csv

            tc = '-' + test_case + '-'
            pattern = re.compile(r"(\w*)-(\w*)-(\w*)" + tc + \
                r"(nx-\d*-ny-\d*-nz-\d*)-nodes-(\d*)" + self.timing_csv)

            self.configs = {}
            for compiler_suite in compiler_suites:
                path = os.path.join(self.path, test_case, compiler_suite)
                if not os.path.exists(path):
                    raise RuntimeError("Path '" + path + "' does not exist. Exiting.")

                for fname in os.listdir(path=path):
                    m = re.match(pattern, fname)
                    if not m is None:
                        machine = m.group(1)
                        group = machine + '-' + m.group(2) + '-' + m.group(3) + tc + m.group(4)

                        if not machine in self.configs.keys():
                            self.configs[machine] = {}
                            self.configs[machine]['groups'] = {}
                            self.configs[machine]['compilers'] = set()
                            self.configs[machine]['grids'] = set()
                            self.configs[machine]['comms'] = set()

                        if not group in self.configs[machine]['groups']:
                            self.configs[machine]['groups'][group] = {
                                'path':     path,
                                'basename': group + '-nodes-',
                                'compiler': m.group(2),
                                'comm':     m.group(3),
                                'grid':     m.group(4),
                                'nodes':    []
                            }
                        self.configs[machine]['compilers'].add(m.group(2))
                        self.configs[machine]['comms'].add(m.group(3))
                        self.configs[machine]['grids'].add(m.group(4))
                        self.configs[machine]['groups'][group]['nodes'].append(int(m.group(5)))

                    if "submit" in fname:
                        with open(os.path.join(path, fname)) as lines:
                            for line in lines:
                                result = re.findall(r'--ntasks-per-node=(\d*)', line)
                                if result == []:
                                    result = re.findall(r'--tasks-per-node=(\d*)', line)
                                if not result == []:
                                    for machine in self.configs.keys():
                                        if machine in fname:
                                            self.configs[machine]['ntasks_per_node'] = result[0]

            print("Found", len(self.configs.keys()), "different machines with the following configurations:")
            for machine in self.configs.keys():
                print("*", machine + ":")
                print("\t", len(self.configs[machine]['compilers']),
                      "compiler(s):", self.configs[machine]['compilers'])
                print("\t", len(self.configs[machine]['comms']), "comm method(s):",
                      self.configs[machine]['comms'])
                print("\t", len(self.configs[machine]['grids']),
                      "grid configuration(s):", self.configs[machine]['grids'])
                print("\t", "  number of tasks per node:", self.configs[machine]['ntasks_per_node'])
                print()

            # sort nodes
            for machine in self.configs.keys():
                for group in self.configs[machine]['groups'].keys():
                    config = self.configs[machine]['groups'][group]
                    config['nodes'].sort()

        def _get_data(self, config, nodes, what, dtype, csv, measure='mean-std', nruns=-1):
            measure_1_data = {}
            measure_2_data = {}
            for long_name in what:
                measure_1_data[long_name] = np.zeros(len(nodes))
                measure_2_data[long_name] = np.zeros(len(nodes))

            for i, node in enumerate(nodes):
                fname = config['basename'] + str(node) + csv

                df = pd.read_csv(os.path.join(config['path'], fname), dtype=dtype)

                long_names = list(df.columns)
                for w in what:
                    if not w in long_names:
                        raise RuntimeError("Data '" + w + "' not in data set.")

                for long_name in what:
                    data = np.array(df.loc[:, long_name])

                    if nruns == -1:
                        # use all data
                        pass
                    elif nruns > data.size:
                        raise RuntimeError("Only " + str(data.size) + " runs available.")
                    else:
                        data = data[-nruns:]
                        if not nruns == data.size:
                            raise RuntimeError("Something went wrong in obtaining data.")



                    if measure == 'mean-std':
                        measure_1_data[long_name][i] = data.mean()
                        measure_2_data[long_name][i] = data.std()
                    elif measure == 'min-max':
                        measure_1_data[long_name][i] = data.min()
                        measure_2_data[long_name][i] = data.max()
                    else:
                        raise RuntimeError("Only 'mean-std' or 'min-max' measure.")

            return measure_1_data, measure_2_data


        def get_timing(self, config, nodes, timings, nruns):
            return self._get_data(config=config,
                                  nodes=nodes,
                                  what=timings,
                                  dtype=np.float64,
                                  csv=self.timing_csv,
                                  measure='mean-std',
                                  nruns=nruns)

        def get_comm_stats(self, config, nodes, stats):
            return self._get_data(config=config,
                                  nodes=nodes,
                                  what=stats,
                                  dtype=np.int64,
                                  csv=self.ncalls_csv,
                                  measure='min-max')

        def get_mesh(self, grid):
            pat = re.compile(r"nx-(\d*)-ny-(\d*)-nz-(\d*)")
            g = re.match(pat, grid)
            return int(g.group(1)), int(g.group(2)), int(g.group(3))

        def get_sorted_grids(self, machine):
            triples = []
            for grid in self.configs[machine]['grids']:
                nx, ny, nz = self.get_mesh(grid)
                triples.append((nx, ny, nz))
            triples.sort()
            grids = []
            for (nx, ny, nz) in triples:
                grids.append('nx-' + str(nx) + '-ny-' + str(ny) + '-nz-' + str(nz))
            return grids


    # :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    def add_to_plot(ax, dset, nruns, config, timings, cmap, marker, add_label=False,
                    add_ideal_scaling=False):
        nodes = np.asarray(config['nodes'])

        # switch case:
        # (see https://docs.python.org/3.10/whatsnew/3.10.html#pep-634-structural-pattern-matching, 28 Jan 2025)
        method = ''
        match config['comm']:
            case 'p2p':
                method = 'MPI-3 P2P'
            case 'rma':
                method = 'MPI-3 RMA'
            case 'shmem':
                method = 'SHMEM'
            case _:
                raise RuntimeError("No method called '" + config['comm'] + "'.")
        # done

        timer_labels = {
            'parcel merge (total)': "parcel merge",
            'find nearest':         "NNS",
            'build graphs':         "DG construction",
            'resolve graphs':       "DG pruning"
        }

        avg_data, std_data = dset.get_timing(config, nodes, timings, nruns)

        if add_ideal_scaling:
            label = None
            if add_label:
                label = 'ideal scaling'

            ax.plot(nodes,
                    avg_data[timings[0]][0] / nodes * nodes[0],
                    color='black',
                    linestyle='dashed',
                    linewidth=1,
                    label=label)

        for i, long_name in enumerate(timings):
            label = None
            if add_label:
                if long_name in timer_labels.keys():
                    label = timer_labels[long_name]

            ax.errorbar(x=nodes,
                        y=avg_data[long_name],
                        yerr=std_data[long_name],
                        #yerr=abs(avg_data[long_name]-std_data[long_name]),
                        label=label,
                        color=cmap(i),
                        linewidth=1,
                        marker=marker,
                        markersize=5,
                        capsize=3)

    # :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    # Create legend where markers share a single legend entry:
    def add_legend(ax, add_ideal_scaling, **kwargs):
        handles, labels = ax.get_legend_handles_labels()

        arg = {}
        if add_ideal_scaling:
            arg['ideal scaling'] = None
        for t in labels:
            arg[t] = []

        for i in range(len(labels)):
            if labels[i] == 'ideal scaling':
                arg['ideal scaling'] = handles[i]
            else:
                arg[labels[i]].append(handles[i])

        h_ = []
        for l in arg.keys():
            h_.append(arg[l])

        # 23 Jan 2025
        # https://matplotlib.org/stable/gallery/text_labels_and_annotations/legend_demo.html
        ax.legend(loc='lower left', handles=h_, labels=arg.keys(),
                  ncols=2,
                  columnspacing=0.8,
                  handler_map={list: HandlerTuple(ndivide=None)},
                  **kwargs)

    # :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    def generate_stats_plot(dset, machine, args):

        print("Generating a " + args.plot + " plot for " + machine + ".")

        for compiler_suite in args.compiler_suites:

            if not compiler_suite in dset.configs[machine]['compilers']:
                continue

            grids = dset.get_sorted_grids(machine)
            n = len(grids)
            nrows = int(np.sqrt(n))
            ncols = int(n / nrows + 0.5)

            sharex = (nrows > 1)

            fig, axs = plt.subplots(nrows=nrows,
                                    ncols=ncols,
                                    sharey=True,
                                    sharex=sharex,
                                    figsize=(4.5*ncols, 4.25*nrows),
                                    dpi=400)
            axs_fl = axs.flatten()

            stats = {
                'p2p': ['MPI P2P put', 'MPI P2P get'],
                'rma': ['MPI RMA put', 'MPI RMA get'],
                'shmem': ['SHMEM put', 'SHMEM get']
            }

            cmap = plt.get_cmap(args.colour_map)

            comms = dset.configs[machine]['comms']
            for i, comm in enumerate(comms):

                axs_fl[i].grid(which='both', linestyle='dashed', linewidth=0.25)

                stat = stats[comm]

                for j, grid in enumerate(grids):


                    #axs_fl[i].set_title(dset.titles[comm])
                    # -----------------------------------------------------------
                    # Add bar to figure:
                    tag = machine + '-' + compiler_suite + '-' + comm + '-' + args.test_case + '-' + grid

                    configs = dset.configs[machine]

                    groups = list(configs['groups'].keys())

                    n_conf = sum(tag in group for group in groups)

                    for group in groups:

                        if not tag in group:
                            continue

                        config = configs['groups'][group]

                        nodes = np.asarray(config['nodes'])
                        min_data, max_data = dset.get_comm_stats(config, nodes, stat)

                        print(stat[0], "\tmin:", min(min_data[stat[0]]), "\tmax:", max(max_data[stat[0]]))
                        print(stat[1], "\tmin:", min(min_data[stat[1]]), "\tmax:", max(max_data[stat[1]]))

                        #axs_fl[i].plot(nodes, max_data[stat[0]],
                                       #color=cmap(0),
                                       #linewidth=1,
                                       #marker=args.markers[0],
                                       #markersize=5)

                        #axs_fl[i].plot(nodes, max_data[stat[1]],
                                       #color=cmap(1),
                                       #linewidth=1,
                                       #marker=args.markers[1],
                                       #markersize=5)

                    # -----------------------------------------------------------
                    # Create legend where markers share a single legend entry:
                    #add_legend(axs_fl[i],
                            ##title=r'\bfseries{' + dset.titles[comm] + r'}',
                            #alignment='left')

                    #axs_fl[i].set_yscale('log', base=10)
                    #axs_fl[i].set_xscale('log', base=2)

                    #if i >= (nrows - 1) * ncols:
                        #axs_fl[i].set_xlabel('number of nodes (1 node = ' + \
                            #str(dset.configs[machine]['ntasks_per_node']) + ' cores)')

                #if nrows > 1:
                    #for i in range(nrows):
                        #axs[i, 0].set_ylabel('number of calls')
                #else:
                    #axs[0].set_ylabel('number of calls')

            ## -----------------------------------------------------------
            ## Save figure:
            #plt.tight_layout()

            #if not os.path.exists(args.output_dir):
                #os.makedirs(args.output_dir)

            #tag = ''
            #if dset.use_subcomm:
                #tag = '-subcomm'

            #plt.savefig(os.path.join(args.output_dir, machine + '-' + compiler_suite + \
                #'-' + args.test_case + tag + '-comm-stats.pdf'), bbox_inches='tight')
            #plt.close()

    # :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    def generate_scaling_plot(dset, machine, args):

        print("Generating a " + args.plot + " plot for " + machine + ".")

        n = len(dset.configs[machine]['comms'])
        nrows = int(np.sqrt(n))
        ncols = int(n / nrows + 0.5)

        sharex = (nrows > 1)

        comms = sorted(dset.configs[machine]['comms'])

        for compiler_suite in args.compiler_suites:

            if not compiler_suite in dset.configs[machine]['compilers']:
                continue

            fig, axs = plt.subplots(nrows=nrows,
                                    ncols=ncols,
                                    sharey=True,
                                    sharex=sharex,
                                    figsize=(4.5*ncols, 4.25*nrows),
                                    dpi=400)
            axs_fl = axs.flatten()

            for i, comm in enumerate(comms):
                axs_fl[i].grid(which='both', linestyle='dashed', linewidth=0.25)

                axs_fl[i].set_title(dset.titles[comm])
                # -----------------------------------------------------------
                # Add individual scaling:
                tag = machine + '-' + compiler_suite + '-' + comm + '-' + args.test_case

                configs = dset.configs[machine]

                cmap = plt.get_cmap(args.colour_map)

                markers = args.markers

                groups = list(configs['groups'].keys())

                n_conf = sum(tag in group for group in groups)

                if n_conf > len(markers):
                    raise RuntimeError('Not enough markers. ' + \
                        'Please add more to the command line with --markers')

                found = True
                j = 0
                for group in groups:

                    if not tag in group:
                        continue

                    config = configs['groups'][group]

                    add_to_plot(axs_fl[i],
                                dset,
                                nruns=args.nruns,
                                config=config,
                                timings=args.timings,
                                cmap=cmap,
                                marker=markers[j],
                                add_label=True,
                                add_ideal_scaling=args.add_ideal_scaling)

                    j = j + 1
                    found = False

                # -----------------------------------------------------------
                # Create legend where markers share a single legend entry:
                add_legend(axs_fl[i],
                           add_ideal_scaling=args.add_ideal_scaling,
                            ##title=r'\bfseries{' + dset.titles[comm] + r'}',
                           alignment='left')

                axs_fl[i].set_yscale('log', base=10)
                axs_fl[i].set_xscale('log', base=2)

                if i >= (nrows - 1) * ncols:
                    axs_fl[i].set_xlabel('number of nodes (1 node = ' + \
                        str(dset.configs[machine]['ntasks_per_node']) + ' cores)')

            if nrows > 1:
                for i in range(nrows):
                    axs[i, 0].set_ylabel('run time (s)')
            else:
                axs[0].set_ylabel('run time (s)')

            # -----------------------------------------------------------
            # Save figure:
            plt.tight_layout()

            if not os.path.exists(args.output_dir):
                os.makedirs(args.output_dir)

            tag = ''
            if dset.use_subcomm:
                tag = '-subcomm'

            plt.savefig(os.path.join(args.output_dir, machine + '-' + compiler_suite + \
                '-' + args.test_case + tag + '-scaling.pdf'), bbox_inches='tight')
            plt.close()

    # :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    def generate_strong_efficiency_plot(dset, machine, args):

        timing = args.timings[0]

        print("Generating a " + args.plot + " plot of " + timing + " for " + machine + ".")

        tf = timing.replace(' ', '-')
        for c in ['(', ')']:
            tf = tf.replace(c, '')

        cmap = plt.get_cmap(args.colour_map)

        grids = dset.get_sorted_grids(machine)

        n = len(grids)
        nrows = int(np.sqrt(n))
        ncols = int(n / nrows + 0.5)

        # -----------------------------------------------------------
        # Create figure:
        fig, axs = plt.subplots(nrows=nrows,
                                ncols=ncols,
                                sharey=True,
                                sharex=False,
                                figsize=(5*ncols, 5*nrows),
                                dpi=400)
        axs_fl = axs.flatten()
        for j, grid in enumerate(grids):

            nx, ny, nz = dset.get_mesh(grid)
            if args.enable_latex:
                title = r'$(nx = ' + str(nx) + \
                        r')\times(ny = ' + str(ny) + \
                        r')\times(nz = ' + str(nz) + r')$'
            else:
                title = r'(nx = ' + str(nx) + \
                        r') x (ny = ' + str(ny) + \
                        r') x (nz = ' + str(nz) + r')'

            axs[j].set_title(title)

            axs[j].grid(which='both', linestyle='dashed', linewidth=0.25, axis='y')

            # -----------------------------------------------------------
            # Add individual scaling:
            comms = sorted(args.comm)
            n_comms = len(comms)
            width= 0.4 / n_comms
            for i, comm in enumerate(comms):
                tag = args.compiler_suite + '-' + comm + '-' + args.test_case + '-' + grid

                axs[j].axhline(y=1, linestyle='solid', color='black', linewidth=0.75)

                label = dset.titles[comm]
                offset = width * (i - 0.5*n_comms)
                add_bar(axs[j],
                        dset,
                        tag,
                        timing,
                        comm,
                        args,
                        offset=offset,
                        width=width,
                        color=cmap(i),
                        edgecolor='black',
                        hatch=args.hatches[i],
                        label=label)

                axs[j].legend(loc='upper left', ncols=int((n_comms+1) / 2))

                axs[j].set_xlabel('number of nodes (1 node = 128 cores)')
                axs[j].set_ylim([0, 1.6])

        if nrows > 1:
            for i in range(nrows):
                axs[i, 0].set_ylabel('strong parallel efficiency')
        else:
            axs[0].set_ylabel('strong parallel efficiency')


        # -----------------------------------------------------------
        # Save figure:
        plt.tight_layout()
        fname = args.compiler_suite + '-' + tf + '-' + args.plot + '.pdf'

        if not os.path.exists(args.output_dir):
            os.makedirs(args.output_dir)

        plt.savefig(fname, bbox_inches='tight')
        plt.close()


    # :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    def add_bar(ax, dset, machine, tag, timing, comm, args, offset, **kwargs):

        configs = dset.configs[machine]

        markers = args.markers

        groups = list(configs.keys())

        n_conf = sum(tag in group for group in groups)

        if n_conf > len(markers):
            raise RuntimeError('Not enough markers. ' + \
                'Please add more to the command line with --markers')

        for group in groups:

            if not tag in group:
                continue

            config = configs[group]

            nodes = np.asarray(config['nodes'])

            avg_data, std_data = dset.get_timing(config, nodes, args.timings)

            # Calculate strong parallel efficiency:
            #   S(p) = T(1) / T(p)
            #   E(p) = S(p) / p
            speedup = avg_data[timing][0] / avg_data[timing]
            p = nodes / nodes[0]
            eff = speedup / p

            x = np.arange(len(eff))
            ax.bar(x=x+offset,
                   height=eff,
                   align='edge',
                   **kwargs)

            ax.set_xticks(x, nodes)

    # :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    # Actual 'main':
    #

    parser = argparse.ArgumentParser(
            description="Generate benchmark plots."
    )

    parser.add_argument(
        "--compiler-suites",
        type=str,
        nargs='+',
        default="cray",
        help="Compiler environment",
    )

    parser.add_argument(
        "--test-case",
        type=str,
        default="random",
        choices=['random', 'read-early', 'read-late'],
        help="Test case to analyse.",
    )

    parser.add_argument(
        "--comm",
        type=str,
        nargs='+',
        default=['p2p', 'rma', 'shmem'],
        choices=['p2p', 'rma', 'shmem'],
        help="Communication method.",
    )

    parser.add_argument(
        "--timings",
        type=str,
        nargs='+',
        default=['parcel merge (total)', 'find nearest', 'build graphs', 'resolve graphs'],
        help="Timer data to visualise.",
    )

    parser.add_argument(
        "--path",
        type=str,
        default='.',
        help="Data directory.",
    )

    parser.add_argument(
        "--colour-map",
        type=str,
        default='tab10',
        help="Colour map for plotting."
    )

    parser.add_argument(
        "--markers",
        type=str,
        nargs='+',
        default=['o', 's', 'D'],
        help="Markers for line plot."
    )

    parser.add_argument(
        "--hatches",
        type=str,
        nargs='+',
        default=['o', '/', 'x', '*', '\\', '|'],
        help="Markers for line plot."
    )

    parser.add_argument(
        "--plot",
        type=str,
        default='weak-strong-scaling',
        choices=['weak-strong-scaling',
                 'strong-efficiency',
                 'comm-stats'],
        help="Type of benchmark figure.")

    parser.add_argument(
        "--enable-latex",
        action='store_true',
        help="Use LateX for plot labels."
    )

    parser.add_argument(
        "--use-subcomm",
        action='store_true',
        help="Use sub-communicator data."
    )

    parser.add_argument(
        "--output-dir",
        type=str,
        default=".",
        help="Figure save directory."
    )

    parser.add_argument(
        "--nruns",
        type=int,
        default=-1,
        help="Number of runs to use. Default: -1 (use all available)"
    )

    parser.add_argument(
        "--add-ideal-scaling",
        action='store_true',
        help="Add ideal scaling line to plot."
    )

    args = parser.parse_args()

    plt.rcParams['text.usetex'] = args.enable_latex

    dset = DataSet(args.path, args.compiler_suites, args.test_case, args.use_subcomm)

    for machine in dset.configs.keys():
        match args.plot:
            case 'weak-strong-scaling':
                generate_scaling_plot(dset, machine, args=args)
            case 'strong-efficiency':
                generate_strong_efficiency_plot(dset, machine, args=args)
            case 'comm-stats':
                generate_stats_plot(dset, machine, args=args)
            case _:
                # raise error even though it is impossible to land here
                raise RuntimeError("No plotting functionality '" + args.plot + "'.")
        # done match

except Exception as ex:
    print(ex, flush=True)

