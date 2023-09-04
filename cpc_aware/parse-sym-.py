import glob
import matplotlib.pyplot as plt
# Find all files that match the 'sym-plc*' pattern
files = glob.glob("./test/sym-naive*.txt")

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
summed_cpu_sysbench = 0
amount_cpu_sysbench = 0


# Read the latest file if one exists
if files:
    with open(files[0], 'r') as f:
        lines = f.readlines()
        current_cpu = -1
        for line in lines:
            # Update the current CPU if we see a "cpu#X" line
            if "total number of events" in line:
                cpu_amount = int(line.split()[-1])
                amount_cpu_sysbench += 1
                summed_cpu_sysbench += cpu_amount
                
    print("Amount of cpu sysbench counts:", amount_cpu_sysbench)
    print("Average of cpu sysbench counts:", summed_cpu_sysbench/amount_cpu_sysbench)
else:
    print("No matching files found.")