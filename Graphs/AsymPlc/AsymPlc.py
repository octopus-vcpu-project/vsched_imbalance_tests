import glob
import matplotlib.pyplot as plt

def percentage_normalize(values):
    total = sum(values)
    if total == 0:
        return [0 for _ in values]
    return [(value / total) * 100 for value in values]

def process_file(n, s):
    files = glob.glob(s)
    files.sort(reverse=True)

    if len(files) >= n:
        file_to_read = files[n-1]
        cpu_sysbench_counts = []
        with open(file_to_read, 'r') as f:
            lines = f.readlines()
            current_cpu = -1
            for line in lines:
                if line.startswith("cpu#"):
                    current_cpu = int(line.split('#')[1].split(',')[0])
                    while len(cpu_sysbench_counts) <= current_cpu:
                        cpu_sysbench_counts.append(0)
                elif "sysbench" in line and current_cpu != -1:
                    cpu_sysbench_counts[current_cpu] += 1

        return percentage_normalize(cpu_sysbench_counts)
    else:
        print(f"No matching file found for index {n}")
        return []

def plot_data(index1, index2):
    dataset1 = process_file(index1, "./1-asym-plc-01181602.txt")
    dataset2 = process_file(index2, "./1-asym-plc-01181832.txt")

    plt.figure(figsize=(11, 10))
    max_length = max(len(dataset1), len(dataset2))

    for i in range(max_length):
        value1 = dataset1[i] if i < len(dataset1) else 0
        value2 = dataset2[i] if i < len(dataset2) else 0

        if value1 > value2:
            plt.bar(i, value1, color='blue')
            plt.bar(i, value2, color='green')
        else:
            plt.bar(i, value2, color='green')
            plt.bar(i, value1, color='blue')

    plt.xlabel('vCPU', fontsize=35)
    plt.xticks(range(0, max_length, 3), fontsize=35)
    plt.ylabel("Percentage of execution \n time per vCPU", fontsize=35)
    plt.title('', fontsize=35)
    plt.legend(['CFS', 'CFS+vProbing'],loc="upper left", prop={'size': 30})
    plt.subplots_adjust(left=0.463, bottom=0.471)
    plt.xticks(rotation=-20,ha='left')
    # Adjust y-axis tick font size
    plt.yticks(fontsize=35)
    plt.tight_layout()
    plt.show()

# Example usage
plot_data(1, 1)
