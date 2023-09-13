import glob
import matplotlib.pyplot as plt
# Find all files that match the 'sym-plc*' pattern
instance_1 = glob.glob("./test/unfair*.txt")

# Sort the files to get the latest one
instance_1.sort(reverse=True)
# Read the latest file if one exists
if instance_1:
    with open(instance_1[0], 'r') as f:
        print(f"Reading {instance_1[0]}")
        
else:
    print("No matching files found.")


vruntime_per_thread = {}
# Read the latest file if one exists
if instance_1:
    with open(instance_1[0], 'r') as f:
        ln_1 = f.readlines()
        current_thread = "null"
        for line in ln_1:
            if "ThreadID" in line:
                current_thread = line.split(': ')[1]
            elif "se.vruntime" in line:
                vruntime = int(line.split(': ')[1][:-1].strip())
                if current_thread in vruntime_per_thread:
                    vruntime_per_thread[current_thread].append(vruntime)
                else:
                    vruntime_per_thread[current_thread] = [vruntime]
else:
    print("No matching files found.")


print(vruntime_per_thread)

