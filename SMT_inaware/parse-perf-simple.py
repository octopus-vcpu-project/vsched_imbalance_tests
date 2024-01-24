import matplotlib.pyplot as plt
import numpy as np

# Data
nginx_matmul3 = {
    "Matmul": [100],
    "Nginx": [100],
    "Matmul+vProber": [113.89],
    "Nginx+vProber": [104.927]
}

nginx_matmul2 = {
    "Matmul": [100],
    "FIO": [100],
    "Matmul+vProber": [118.26],
    "FIO+vProber": [99.097]
}

# Labels and values for nginx_matmul3
labels_3 = list(nginx_matmul3.keys())
values_3 = [nginx_matmul3[label][0] for label in labels_3]

# Labels and values for nginx_matmul2
labels_2 = list(nginx_matmul2.keys())
values_2 = [nginx_matmul2[label][0] for label in labels_2]

# Aligning the labels and ensuring both sets have the same labels
all_labels = set(labels_3 + labels_2)
values_3_aligned = [nginx_matmul3.get(label, [None])[0] for label in all_labels]
values_2_aligned = [nginx_matmul2.get(label, [None])[0] for label in all_labels]

# Number of groups
n_groups = len(all_labels)

# Creating the plot
fig, ax = plt.subplots()

index = np.arange(n_groups)
bar_width = 0.35
opacity = 0.8

rects1 = ax.bar(index, values_3_aligned, bar_width,
                alpha=opacity, color='b',
                label='nginx_matmul3')

rects2 = ax.bar(index + bar_width, values_2_aligned, bar_width,
                alpha=opacity, color='g',
                label='nginx_matmul2')

ax.set_xlabel('Category')
ax.set_ylabel('Scores')
ax.set_title('Scores by category and test')
ax.set_xticks(index + bar_width / 2)
ax.set_xticklabels(all_labels)
ax.legend()

plt.show()
