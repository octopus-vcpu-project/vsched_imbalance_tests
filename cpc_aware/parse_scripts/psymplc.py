import glob
import matplotlib.pyplot as plt
# Find all files that match the 'sym-plc*' pattern
files = glob.glob("./test/sym-plc-smrt*.txt")

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
def process_file(n,s):
    res = []
    files = glob.glob(s)
    files.sort(reverse=True)
# Read the latest file if one exists
    if len(files) >= n:
        file_to_read = files[n-1]
        with open(file_to_read, 'r') as f:
            lines = f.readlines()
            current_cpu = -1
            for line in lines:
                # Update the current CPU if we see a "cpu#X" line
                if line.startswith("runqocc, CPU"):
                    cpu = int(line.split('CPU')[1].split(' ')[1])
                    occ = float(line.split('CPU')[1].split(' ')[-1].split("%")[0])
                    while len(res) <= cpu:
                        res.append([])
                    res[cpu].append(occ)
                # Count 'sysbench' occurrences for the current CPU
        res_f=[]
        for x in range(0,len(res)):
            res_f.append(sum(res[x])/len(res[x]))
        print(res_f)
        plt.bar(range(len(res_f)), res_f)
        plt.xlabel('CPU Number')
        plt.ylabel('Number of sysbench Occurrences')
        plt.title('sysbench Occurrences by CPU')
        plt.show()
        return res_f
    else:
        print("No matching files found.")

def plot_data(index1, index2):
    dataset1 = process_file(index1,"./test/sym-plc012*.txt")
    print(dataset1)
    dataset2 = process_file(index2,"./test/sym-plc-smrt*.txt")
    print(sum(dataset2))
    print(sum(dataset1))
    plt.figure(figsize=(10, 6))
    max_length = max(len(dataset1), len(dataset2))
    # Iterate over each pair of bars and plot the shorter one in front
    for i in range(max(len(dataset1), len(dataset2))):
        value1 = dataset1[i] if i < len(dataset1) else 0
        value2 = dataset2[i] if i < len(dataset2) else 0

        # Determine which value is smaller and plot it second (on top)
        if value1 > value2:
            plt.bar(i, value1, color='blue')
            plt.bar(i, value2, color='green')
        else:
            plt.bar(i, value2, color='green')
            plt.bar(i, value1, color='blue')

    plt.xlabel('vCPU')
    plt.xticks(range(0,max_length,3))
    plt.ylabel("Percentage of execution \n time per vCPU")
    plt.title('')
    plt.legend(['CFS+vProbing', 'CFS'])
    plt.subplots_adjust(left=0.463, bottom=0.471)
    plt.show()

plot_data(1,1)