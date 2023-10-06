import glob
import matplotlib.pyplot as plt
from collections import Counter

# Find all files that match the 'sym-plc*' pattern
files = glob.glob("../NUMA_inaware-1/tests/plc_out2*.txt")

# Sort the files to get the latest one
files.sort(reverse=True)

# Read the latest file if one exists
if files:
    with open(files[0], 'r') as f:
        print(f"Reading {files[0]}")
        print(f.read())
else:
    print("No matching files found.")

# Initialize an empty list to hold the counts
cpu_sysbench_counts = []

# Read the latest file if one exists
if files:
    with open(files[0], 'r') as f:
        lines = f.readlines()
        current_cpu = -1
        used_phys_cpus = []
        incorrect = 0
        incorrect_list = []
        for line in lines:
            # Update the current CPU if we see a "cpu#X" line
            if line.startswith("cpu#"):
                current_cpu = int(line.split('#')[1].split(',')[0])
           
                while len(cpu_sysbench_counts) <= current_cpu:
                    cpu_sysbench_counts.append(0)
                print(current_cpu)
                if(current_cpu==31):
                        incorrect_list.append(incorrect)
                        used_phys_cpus = []
                        incorrect=0
            # Count 'sysbench' occurrences for the current CPU
            elif "hackbench" in line or "wrk" in line:
                if current_cpu != -1:
                    if(not (current_cpu//2) in used_phys_cpus):
                        incorrect += 1
                        used_phys_cpus.append(current_cpu//2)
                    cpu_sysbench_counts[current_cpu] += 1
    print("Physical cores used", incorrect_list)
    # Plot
    plt.bar(range(len(cpu_sysbench_counts)), cpu_sysbench_counts)
    plt.xlabel('Value')
    plt.ylabel('Number of Occurrences')
    plt.title('Value vs. Number of Occurrences')
    plt.show()
    
else:
    print("No matching files found.")