import matplotlib.pyplot as plt
import numpy as np

# Data
bar_width=0.40
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

source=2
gap_between=1
# Prepare data for plotting
labels_3 = list(nginx_matmul3.keys())
labels_2 = list(nginx_matmul2.keys())
values_3 = list(nginx_matmul3.values())
values_2 = list(nginx_matmul2.values())

matmul_pt_1=[100,113.89,100,118.26]
nginx_test=[100,104.927]
fio_test=[100,99.097]

start_of_gap=source+(bar_width*4)

# Plotting parameters
bar_width = 0.40
space_between_groups = 0.4
index_3 = np.arange(len(labels_3))
print("index 3",index_3)
index_2 = np.arange(len(labels_2)) + max(index_3) + space_between_groups
# Creating the plot
fig, ax = plt.subplots(figsize=(4, 3))
# Plotting the bars for nginx_matmul3 and nginx_matmul2
bars_3 = ax.bar([source,source+(bar_width*2),start_of_gap+gap_between,start_of_gap+gap_between+bar_width*2], matmul_pt_1, bar_width, label='Matmul')
bars_2 = ax.bar([source+bar_width,source+(bar_width*3)], nginx_test, bar_width, label='Nginx')
bars_ = ax.bar([start_of_gap+gap_between+bar_width,start_of_gap+gap_between+(bar_width*3)], fio_test, bar_width, label='FIO')
# Adding labels and titles
ax.set_ylim([0,140])
ax.set_ylabel("Normalized throughput (%)\n(relative to CFS)")
ax.set_xticks([source+bar_width*1/2,source+(bar_width*3)-bar_width*1/2,start_of_gap+gap_between+bar_width*1/2,start_of_gap+gap_between+bar_width*2.5])
ax.set_xticklabels(["CFS","CFS+vProber","CFS","CFS+vProber"])
plt.xticks(rotation=-20,ha='left')

ax.legend(loc="upper left",ncol=3,columnspacing=0.4,bbox_to_anchor=(0, 1.2))

# Show the plot
plt.tight_layout()
plt.show()