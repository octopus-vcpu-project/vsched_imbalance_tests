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
    normal_len=40
    correction_factor=300
    corrective_factor = normal_len/(len(v)-1)
    g=[]
    for x in range(0,len(v)):
        g.append(x*corrective_factor)
    print(g[len(v)-1])
    return g

def graph_lst(pin_cs,smrt_cs,nve_cs):
    
    for k, v in pin_cs.items():
        plt.plot(get_correct_range(v), v, '.-',color='green', label="pinned")
    for k, v in smrt_cs.items():
        plt.plot(get_correct_range(v), v, '.-',color='red',label="smrt")

    plt.legend()  # To draw legend
    plt.show()


biggest=-99999999999
pin_cs = try_test("./test/unf-asym-pin-*.txt")
smrt_cs = try_test("./test/unf-asym-smrt-*.txt")
nve_cs = try_test("./test/unf-asym-nve-*.txt")
graph_lst(pin_cs,smrt_cs,nve_cs)
