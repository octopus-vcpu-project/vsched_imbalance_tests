import matplotlib.pyplot as plt
import numpy as np

# Data
nginx_matmul3 = {
    "Matmul": 100,
    "Nginx": 100,
    "Matmul+vProber": 113.89,
    "Nginx+vProber": 104.927
}

nginx_matmul2 = {
    "Matmul": 100,
    "FIO": 100,
    "Matmul+vProber": 118.26,
    "FIO+vProber": 99.097
}

# Prepare data for plotting
labels_3 = list(nginx_matmul3.keys())
labels_2 = list(nginx_matmul2.keys())
values_3 = list(nginx_matmul3.values())
values_2 = list(nginx_matmul2.values())

# Plotting parameters
bar_width = 0.35
space_between_groups = 1.5
index_3 = np.arange(len(labels_3))
index_2 = np.arange(len(labels_2)) + max(index_3) + space_between_groups

# Creating the plot
fig, ax = plt.subplots()

# Plotting the bars for nginx_matmul3 and nginx_matmul2
bars_3 = ax.bar(index_3, values_3, bar_width, label='nginx_matmul3')
bars_2 = ax.bar(index_2, values_2, bar_width, label='nginx_matmul2')

# Adding labels and titles
ax.set_xlabel('Category')
ax.set_ylabel('Scores')
ax.set_title('Scores by category for each dataset')
ax.set_xticks(np.concatenate((index_3, index_2)))
ax.set_xticklabels(labels_3 + labels_2)
ax.legend()

# Show the plot
plt.show()