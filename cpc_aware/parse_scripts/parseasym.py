import glob
import matplotlib.pyplot as plt
# Find all files that match the 'sym-plc*' pattern
files = glob.glob("./test/asym-opt*.txt")
badfiles = glob.glob("./test/asym-naive*.txt")

# Sort the files to get the latest one
files.sort(reverse=True)
badfiles.sort(reverse=True)
# Read the latest file if one exists
if files and badfiles:
    with open(files[0], 'r') as f:
        print(f"Reading {files[0]}")
        print(f.read())
    with open(badfiles[0], 'r') as f:
        print(f"Reading {files[0]}")
        print(f.read())
else:
    print("No matching files found.")


# Initialize an empty list to hold the counts
summed_cpu_sysbench = 0
amount_cpu_sysbench = 0
list_sysbench_good = []
list_sysbench_bad = []
lowest_value = 999999999999
highest_value = 0
median_value = 0

# Read the latest file if one exists
if files and badfiles:
    with open(files[0], 'r') as f,open(badfiles[0], 'r') as w:
        lines = f.readlines()
        badlines = w.readlines()
        current_cpu = -1
        for line in lines:
            # Update the current CPU if we see a "cpu#X" line
            if "total number of events" in line:
                cpu_amount = int(line.split()[-1])
                amount_cpu_sysbench += 1
                summed_cpu_sysbench += cpu_amount
                list_sysbench_good.append(cpu_amount)
                if(cpu_amount >= highest_value):
                    highest_value = cpu_amount
                if(cpu_amount <= lowest_value):
                    lowest_value = cpu_amount
        
        for line in badlines:
            # Update the current CPU if we see a "cpu#X" line
            if "total number of events" in line:
                cpu_amount = int(line.split()[-1])
                amount_cpu_sysbench += 1
                summed_cpu_sysbench += cpu_amount
                list_sysbench_bad.append(cpu_amount)
                if(cpu_amount >= highest_value):
                    highest_value = cpu_amount
                if(cpu_amount <= lowest_value):
                    lowest_value = cpu_amount
  
    print("Amount of cpu sysbench counts:", amount_cpu_sysbench)
    print("Average of cpu sysbench counts:", summed_cpu_sysbench/amount_cpu_sysbench)
    print("Lowest performance:", lowest_value)
    print("Highest performance:", highest_value)
else:
    print("No matching files found.")
plt.boxplot([list_sysbench_good, list_sysbench_bad], labels=['Pinned', 'Unpinned'])

# Add title and labels
plt.title('Performance of 4 threads on Asymmetric VM')
plt.xlabel('Lists')
plt.ylabel('Value')

# Show the plot
plt.show()
plt.show()

