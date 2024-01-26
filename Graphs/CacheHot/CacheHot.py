import glob
import matplotlib.pyplot as plt

c_thr_p=[2214,1963,1891,1870,1858,1891,1901]
c_unt_p=[2109,1871,1789,1758,1743,1749,1727]
c_thr_ipc=[0.94,0.93,0.93,0.93,0.93,0.92,0.91]
c_thr_ipc.reverse()
c_unt_ipc=[0.98,0.97,0.97,0.97,0.97,0.97,0.97]
c_unt_ipc.reverse()
diff_list=[0.04978662873,0.04917156601,0.05701509223,0.06370875995,0.06597819851,0.081189251,0.1007527504]
diff_list.reverse()

def normalize_perf_values(x):
    norm = x[0]
    for z in range(0,len(x)):
        x[z] = 2214/x[z] *100

def normalize_IPC_values(x):
    for z in range(0,len(x)):
        x[z] = x[z]/0.98 * 100

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.lines import Line2D
font_size=16

y_tik=[1,2,3,4,8,16,32]
# Create some mock data
t = range(0,7)
data1 = diff_list
for x in range(0,len(data1)):
    data1[x]=data1[x]*100
data2 = c_unt_ipc
print(data1)
fig, ax1 = plt.subplots(figsize=(4, 3))
color = 'tab:red'
ax1.set_xlabel('Active Time(ms)',fontsize=font_size)
ax1.set_ylabel('Performance Difference\n(%)', color=color,fontsize=font_size)
ax1.plot(y_tik, data1,label="Thoroughput Difference",marker="o",color=color)

plt.yticks(fontsize=15)
ax1.tick_params(axis='y', labelcolor=color)

ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis

color = 'tab:blue'
ax2.set_ylabel('IPC', color=color,fontsize=font_size)  # we already handled the x-label with ax1
ax2.plot(y_tik, data2,marker="+",ls="-.",label="Unthrashed IPC", color=color)
ax2.plot(y_tik, c_thr_ipc,marker="+",ls="-.", label="Thrashed IPC",color="grey")
ax2.tick_params(axis='y', labelcolor=color)
ax2.set_ylim(0.88,1.02)
ax2.legend([Line2D([0], [0], color=color,marker="+", ls="-."),Line2D([0], [0], marker="+",ls="-.", color="grey"),Line2D([0], [0], marker="o",color='tab:red')],["IPC Unthrashed","IPC Thrashed","Thoroughput"],framealpha=1,bbox_to_anchor=(0.5, 1.1),loc='upper center')
plt.yticks(fontsize=15)
fig.tight_layout()  # otherwise the right y-label is slightly clipped
plt.show()
