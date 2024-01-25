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
                if "events per second" in line:
                    cpu_amount = float(line.split()[-1])
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
    x = np.arange(len(name_parameters))  # the label locations
    plt.figure(figsize=(12, 8))

    width = 0.02  # Reduced width of the bars
    multiplier = 0
    hatches = ['/', 'x', 'o']  # List of patterns
    colors = ['red', 'green', 'blue']
    other_colors = ['none', 'none', 'blue']
    fig, ax = plt.subplots()

    for i, (attribute, measurement) in enumerate(data_dict.items()):
        offset = width * multiplier
        hatch = hatches[i % len(hatches)]
        rects = ax.bar(x + offset, measurement, width, edgecolor=colors[i], color=other_colors[i], label=attribute, hatch=hatch)
        multiplier += 1

    # Set axis labels and tick labels font size
    ax.set_ylabel('Sysbench Throughput\n(events per second)', fontsize=12)
    ax.set_xticks(x, name_parameters)
    ax.tick_params(axis='both', which='major', labelsize=10)

    # Set larger X and Y limits
    plt.xlim(-0.5, 1000000)  # Adjust as needed
    plt.ylim(0, max([max(values) for values in data_dict.values()]) * 1.2)  # Adjust Y limit to be 20% higher than the highest value

    ax.legend(framealpha=1, fontsize=12)

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

