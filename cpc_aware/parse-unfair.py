import glob
import matplotlib.pyplot as plt
# Find all files that match the 'sym-plc*' pattern
instance_1 = glob.glob("./test/unf-asym-nve-*.txt")

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
                current_thread = line.split(': ')[1][:-1]
            elif "se.sum_exec_runtime" in line:
                print(line)
                vruntime = float(line.split(': ')[1][:-1].strip())
                if current_thread in vruntime_per_thread:
                    vruntime_per_thread[current_thread].append(vruntime)
                else:
                    vruntime_per_thread[current_thread] = [vruntime]
else:
    print("No matching files found.")

biggest=-99999999999
biggest_element=""
smallest=99999999999
smallest_element=""
array_of_lasts=[]
for element,items in vruntime_per_thread.items():
    print(element)
    array_of_lasts.append(items[-1])
    if(vruntime_per_thread[element][-1]>biggest):
        biggest =  vruntime_per_thread[element][-1]
        biggest_element=element
    if(vruntime_per_thread[element][-1]<smallest):
        smallest =  vruntime_per_thread[element][-1]
        smallest_element=element

array_of_lasts.sort()
print("difference is",float((array_of_lasts[-1] - array_of_lasts[0])/array_of_lasts[0]))
print("big value",array_of_lasts)
print(array_of_lasts)
for k, v in vruntime_per_thread.items():
    plt.plot(range(1, len(v) + 1), v, '.-', label=k)
plt.legend()  # To draw legend
plt.show()
print("difference is",float((array_of_lasts[-1] - array_of_lasts[0])/array_of_lasts[0]))

