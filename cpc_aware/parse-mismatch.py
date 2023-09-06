import glob
import matplotlib.pyplot as plt
# Find all files that match the 'sym-plc*' pattern
instance_1 = glob.glob("./test/2-dis-hrd-pm*.txt")
instance_2 = glob.glob("./test/1-dis-hrd-pm*.txt")

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
interval_values_1 = [0]
interval_values_2 = [0]

# Read the latest file if one exists
if instance_1 and instance_2:
    with open(instance_1[0], 'r') as f,open(instance_2[0], 'r') as w:
        ln_1 = f.readlines()
        ln_2 = w.readlines()
        current_cpu = -1
        for line in ln_1:
            # Update the current CPU if we see a "cpu#X" line
            if "thds" in line:
                print(line)

                calculation_num = extract_eps(line)
                print(calculation_num)
                seconds_taken = extract_seconds(line)
                print(seconds_taken)
                accum_calculation = interval_values_1[-1] + calculation_num * 3
                interval_values_1.append(accum_calculation)
            elif "total number of events" in line:
                interval_values_1.append(int(line.split()[-1]))
  
        for line in ln_2:
            # Update the current CPU if we see a "cpu#X" line
            if "thds" in line:
                calculation_num = extract_eps(line)
                seconds_taken = extract_seconds(line)
                accum_calculation = interval_values_2[-1] + calculation_num * 3
                interval_values_2.append(accum_calculation)
            elif "total number of events" in line:
                interval_values_2.append(int(line.split()[-1]))

else:
    print("No matching files found.")


# Generate x-values based on the length of y-values
x_values = list(range(len(interval_values_2)))
for x in range(0,len(x_values)-1):
    x_values[x] = x_values[x] *3
x_values[-1] = x_values[-2] + 2
# Create the plot
plt.figure()

# Plot the first line
plt.plot(x_values, interval_values_1, label='instance 1', marker='o')

# Plot the second line
plt.plot(x_values, interval_values_2, label='instance 2', marker='x')

# Add titles and labels
plt.xlabel('Index')
plt.ylabel('Value')
plt.title('Co-Running Sysbenches in VM with assymetric PM')
plt.legend()

# Show the plot
plt.show()


