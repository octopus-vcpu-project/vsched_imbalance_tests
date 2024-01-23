import glob
import matplotlib.pyplot as plt
def try_test(s):
    # Find all files that match the 'sym-plc*' pattern
    instance_1 = glob.glob(s)
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
                    vruntime = float(line.split(': ')[1][:-1].strip())
                    if current_thread in vruntime_per_thread:
                        vruntime_per_thread[current_thread].append(vruntime)
                    else:
                        vruntime_per_thread[current_thread] = [vruntime]
            return vruntime_per_thread
    else:
        print("No matching files found.")
def get_correct_range(v):
    normal_len=200
    correction_factor=300
    corrective_factor = normal_len/len(v)
    g=[]
    print(range(1, len(v) + 1))
    for x in range(0,len(v)):
        g.append(x*corrective_factor)
    return g

def graph_lst(lst,lst2,lst3):
    
    for k, v in lst3.items():
        plt.plot(get_correct_range(v), v, '.-',color='green', label="dduh")
    for k, v in lst2.items():
        plt.plot(get_correct_range(v), v, '.-',color='red',label="dsuh")

    plt.legend()  # To draw legend
    plt.show()


biggest=-99999999999
vruntime_per_thread = try_test("./test/unf-asym-pin-*.txt")
vruntime_per_thread1 = try_test("./test/unf-asym-smrt-*.txt")
vruntime_per_thread2 = try_test("./test/unf-asym-nve-*.txt")
graph_lst(vruntime_per_thread,vruntime_per_thread1,vruntime_per_thread2)
