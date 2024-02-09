import re
import matplotlib.pyplot as plt
import numpy as np
import glob
cpu_file = './tests/top_inaware_2_cpu09251738.txt'  # Replace with your actual file name

io_file = './tests/top_inaware_2_io09251738.txt'  # Replace with your actual file name

amount_of_tests = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
cpu_increment = 0
io_increment = 0
with open(cpu_file, 'r') as file:
    cpulines = file.readlines()

species = ["", "", "","","","","",""]
penguin_means = {
    'CPU': [],
    'IO': [],
}

def get_average(list):
    return sum(list)/len(list)

def process_file(n,s):
    files = glob.glob(s)
    files.sort(reverse=True)

    if len(files) >= n:
        file_to_read = files[n-1]
        cpu_sysbench_counts = []
        with open(file_to_read, 'r') as f:
            if "total number of events" in line:
                match = re.search(r"total number of events:\s+(\d+)", line)
                if match:
                    print("Sysbench: ", match.group(1))
                    amount_of_tests[cpu_increment // 2][(cpu_increment % 2)* 2 + 1] = match.group(1)
                    species[cpu_increment] = species[cpu_increment] + "+Sysbench"
                    penguin_means["CPU"].append(int(match.group(1)))
                    cpu_increment+=1
                    lines = f.readlines()
            for line in lines:
                if "total number of events" in line:
                    cpu_amount = int(line.split()[-1])
                    cpu_sysbench_counts.append(cpu_amount)
                    print(cpu_amount)

        return get_average(cpu_sysbench_counts)
    else:
        print(f"No matching file found for index {n}")
        return []

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

i = 0
while i < len(cpulines):
    line = cpulines[i].strip()
    if "total number of events" in line:
        match = re.search(r"total number of events:\s+(\d+)", line)
        if match:
            print("Sysbench: ", match.group(1))
            amount_of_tests[cpu_increment // 2][(cpu_increment % 2)* 2 + 1] = match.group(1)
            species[cpu_increment] = species[cpu_increment] + "+Sysbench"
            penguin_means["CPU"].append(int(match.group(1)))
            cpu_increment+=1
            
    elif "computing slice" in line:
        matmul_sum = 0
        while "computing slice" in line or "finished slice" in line or re.match(r"\d+\s+\d+", line):
            if re.match(r"\d+\s+\d+", line):
                _, value = map(int, line.split())
                matmul_sum += value
            i += 1
            if i < len(cpulines):
                line = cpulines[i].strip()
            else:
                break
        print("Matmul Sum: ", matmul_sum)
        if(matmul_sum!= 0):
            amount_of_tests[cpu_increment // 2][(cpu_increment % 2)* 2 + 1] = matmul_sum
            species[cpu_increment] = species[cpu_increment] + "+MATMUL"
            penguin_means["CPU"].append(int(matmul_sum))
            cpu_increment+=1
        continue  # Skip the increment as we already do it in the inner loop
    i += 1


with open(io_file, 'r') as file:
    iolines = file.readlines()
i = 0
while i < len(iolines):
    line = iolines[i].strip()
    if "Transfer/sec" in line:
        match = re.search(r"Transfer/sec:\s+(\d+)", line)
        if match:
            print("Transfers: ", match.group(1))
            amount_of_tests[io_increment // 2][(io_increment % 2)* 2 ] = match.group(1)
            species[io_increment] = species[io_increment] + "+NGINX"
            penguin_means["IO"].append(int(match.group(1)))
            io_increment+=1
        
    
    elif "READ: bw=" in line:
        match = re.search(r"bw=(\d+)", line)
        if match:
            print("rdw: ", match.group(1))
            amount_of_tests[io_increment // 2][(io_increment % 2)* 2 ] = match.group(1)
            species[io_increment] = species[io_increment] + "+FIO"
            penguin_means["IO"].append(int(match.group(1)))
            io_increment+=1
        # Skip the increment as we already do it in the inner loop
    i += 1
print(penguin_means)
x = np.arange(len(species))  # the label locations
width = 0.25  # the width of the bars
multiplier = 0

fig, ax = plt.subplots(layout='constrained')

for attribute, measurement in penguin_means.items():
    offset = width * multiplier
    rects = ax.bar(x + offset, measurement, width, label=attribute)
    ax.bar_label(rects, padding=3)
    multiplier += 1

# Add some text for labels, title and custom x-axis tick labels, etc.
ax.set_ylabel('Length (mm)')
ax.set_title('Penguin attributes by species')
ax.set_xticks(x + width, species)
ax.legend(loc='upper left', ncols=3)

plt.show()
