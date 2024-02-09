import glob
import matplotlib.pyplot as plt
# Find all files that match the 'sym-plc*' pattern
files = glob.glob("./test/sym-plc*.txt")

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
        for line in lines:
            # Update the current CPU if we see a "cpu#X" line
            if line.startswith("cpu#"):
                current_cpu = int(line.split('#')[1].split(',')[0])
                while len(cpu_sysbench_counts) <= current_cpu:
                    cpu_sysbench_counts.append(0)
            # Count 'sysbench' occurrences for the current CPU
            elif "sysbench" in line:
                if current_cpu != -1:
                    cpu_sysbench_counts[current_cpu] += 1
    print("CPU sysbench counts:", cpu_sysbench_counts)
    plt.bar(range(len(cpu_sysbench_counts)), cpu_sysbench_counts)
    plt.xlabel('CPU Number')
    plt.ylabel('Number of sysbench Occurrences')
    plt.title('sysbench Occurrences by CPU')
    plt.show()
else:
    print("No matching files found.")