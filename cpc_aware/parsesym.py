import glob
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import pyplot as plt

# Find all files that match the 'sym-plc*' pattern
def get_average(list):
    return sum(list)/len(list)
def process_file(n,s):
    files = glob.glob(s)
    files.sort(reverse=True)

    if len(files) >= n:
        file_to_read = files[n-1]
        cpu_sysbench_counts = []
        with open(file_to_read, 'r') as f:
            lines = f.readlines()
            current_cpu = -1
            for line in lines:
                if "total number of events" in line:
                    cpu_amount = int(line.split()[-1])
                    cpu_sysbench_counts.append(cpu_amount)
                    print(cpu_amount)

        return get_average(cpu_sysbench_counts)
    else:
        print(f"No matching file found for index {n}")
        return []

nginx_matmul = {
    "Matmul":[25642,35887],
    "Nginx":[2549.80,55.4],
    "Matmul+vProber":[29205,42442],
    "Nginx+vProber":[2675.44,54.9]
}

nginx_matmul1 = {
    "Matmul":[100,100],
    "Nginx":[100,100],
    "Matmul+vProber":[113.89,118.26],
    "Nginx+vProber":[104.927,99.097]
}


def plot_grouped_data_with_legends(data_dict, name_parameters):
    """
    Plots a grouped bar chart for each group in the data dictionary with 
    separate bars for each category in name_parameters, using different patterns for each group.

    :param data_dict: Dictionary with groups as keys and lists of numbers as values.
    :param name_parameters: List of strings representing the categories for the bars in each group.
    """
    x = np.arange(len(name_parameters))# the label locations
    x=x*0.35
    print(x*0.3)
    print(x)
    
    width = 0.08  # the width of the bars
    multiplier = 0
    hatches = ['/', 'x', 'o']  # List of patterns
    colors=['red','green','blue']
    other_colors=['none','none','blue']
    fig, ax = plt.subplots(layout='constrained')

    for i, (attribute, measurement) in enumerate(data_dict.items()):
        offset = width * multiplier
        # Apply a different hatch pattern to each group
        print(x+offset)
        hatch = hatches[i % len(hatches)]

        rects = ax.bar(x + offset, measurement, width, edgecolor=colors[i],color=other_colors[i],lw=2.,label=attribute,hatch=hatch)
        multiplier += 1

    # Add some text for labels, title and custom x-axis tick labels, etc.
    ax.set_ylabel('Sysbench Score')
    ax.set_xticks(x + width, name_parameters)
    plt.ylim(20000, 37000)
    ax.legend(loc='upper left',framealpha=1,prop = { "size": 10 },ncols=3)
    plt.show()
# Initialize an empty list to hold the counts
list_sysbench_opt = process_file(1,"./test/bym-opt*.txt")
list_sysbench_smart = process_file(1,"./test/bym-smrt*.txt")
list_sysbench_naive = process_file(1,"./test/bym-naive*.txt")
asym_opt = process_file(1,"./tests/1-asym-perf-opt-*.txt")
asym_smart = process_file(1,"./tests/1-asym-perf-smart-*.txt")
asym_naive = process_file(1,"./tests/1-asym-perf-naive-*.txt")

data = {
    "CFS":[list_sysbench_naive,asym_naive],
    "CFS+vProber":[list_sysbench_smart,asym_smart],
    "CFS+Pinned":[list_sysbench_opt,asym_opt]
}


plot_grouped_data_with_legends(data,["Symmetric","Assymetric"])

