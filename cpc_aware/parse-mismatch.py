import glob
import matplotlib.pyplot as plt
# Find all files that match the 'sym-plc*' pattern
instance_1 = glob.glob("./test/unf-asy-nve-*.txt")
instance_2 = glob.glob("./test/unf-asym-pin*.txt")

# Sort the files to get the latest one
instance_1.sort(reverse=True)
instance_2.sort(reverse=True)
# Read the latest file if one exists
if instance_1 and instance_2:
    with open(instance_1[0], 'r') as f:
        print(f"Reading {instance_1[0]}")
    with open(instance_2[0], 'r') as f:
        print(f"Reading {instance_2[0]}")
else:
    print("No matching files found.")

def extract_eps(input_string):
    # Split the input string by spaces
    tokens = input_string.split()
    
    # Locate the position of 'eps:' and then get the next element in the list
    try:
        eps_index = tokens.index('eps:') + 1
        eps_value = float(tokens[eps_index])
        return eps_value
    except (ValueError, IndexError):
        return None

def extract_seconds(input_string):
    # Split the input string by spaces
    tokens = input_string.split()
    
    # Locate the position of '[', get the next element, and then remove the 's' at the end
    try:
        seconds_index = tokens.index('[') + 1
        seconds_value = int(tokens[seconds_index].replace('s', '').replace(']', ''))
        return seconds_value
    except (ValueError, IndexError):
        return None


# Initialize an empty list to hold the counts
summed_cpu_sysbench = 0
amount_cpu_sysbench = 0
interval_values_2 = [0]







def process_file(n,s,t):
# Read the latest file if one exists
    interval_values_1 = [0]
    files = glob.glob(s)
    files.sort(reverse=True)
    if len(files) >= n:
        file_to_read = files[n-1]
        with open(file_to_read, 'r') as f:
            ln_1 = f.readlines()
            current_cpu = -1
            for line in ln_1:
                # Update the current CPU if we see a "cpu#X" line
                if "thds" in line:
                    calculation_num = extract_eps(line)
                    seconds_taken = extract_seconds(line)
                    accum_calculation = interval_values_1[-1] + calculation_num * 3
                    interval_values_1.append(accum_calculation)
                elif "total number of events" in line:
                    if(len(interval_values_1)==21):
                        interval_values_1.pop()
                    print("blah",len(interval_values_1))
                    interval_values_1.append(int(line.split()[-1]))
                    if(t==1):
                        interval_values_1 = [0]
                        t=0
                    else:
                        return interval_values_1
    else:
        print("No matching files found.")
def plot_len(new_test,len1,color):
    x_values = list(range(len(new_test)))
    for x in range(0,len(x_values)-1):
        x_values[x] = x_values[x] * 3
    x_values[-1] = x_values[-2] + 3
    print(x_values)
    # Create the plot
    # Plot the first line
    plt.plot(x_values, new_test, color=color,label=len1, marker='o')


def graph_chunk(x,y,color):
    intvl2 = process_file(1,"./test/2-freq-unfair*.txt",x)
    plot_len(intvl2,y,color)
    intvl2 = process_file(1,"./test/1-freq-unfair*.txt",x)
    plot_len(intvl2,y,color)
    intvl2 = process_file(1,"./test/3-freq-unfair*.txt",x)
    plot_len(intvl2,y,color)
    intvl2 = process_file(1,"./test/4-freq-unfair*.txt",x)
    plot_len(intvl2,y,color)

plt.figure()
graph_chunk(1,"Smart","blue")
graph_chunk(0,"Naive","red")

# Generate x-values based on the length of y-values


# Plot the second line

# Add titles and labels
plt.xlabel('Index')
plt.ylabel('Value')
plt.title('Co-Running Sysbenches in VM with assymetric PM')
plt.legend()

# Show the plot
plt.show()


