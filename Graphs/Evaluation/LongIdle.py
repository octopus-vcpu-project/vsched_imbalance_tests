import matplotlib.pyplot as plt
from matplotlib.pyplot import cm
import numpy as np
from matplotlib.colors import hsv_to_rgb
from cycler import cycler
from matplotlib.cm import get_cmap
import matplotlib.pyplot as mpl
# 1000 distinct colors:
colors = mpl.colormaps.get_cmap('viridis').resampled(20).colors
name = "tab10"
cmap = get_cmap(name)  # type: matplotlib.colors.ListedColormap
colors = cmap.colors  # type: list

edge_colors=colors
colors=['none','none',edge_colors[2],'none','none','none']
hatch = ['/', 'x', 'o','\\','.'] 
def prepare_data(groups):
    # Preparing data for plotting
    labels = list(groups.keys())
    values = [groups[label] for label in labels]
    return labels, values

def create_bars(ax, group_labels, values, cluster_labels, bar_width=0.18, font_size=12):
    n_groups = len(values[0])
    bar_positions = []
    for i, group_values in enumerate(values):
        positions = [x*(bar_width*7 + 0.2) + bar_width*i for x in range(n_groups)]
        bar_positions.append(positions)
        print(positions)
        ax.bar(positions, group_values, bar_width, label=group_labels[i],edgecolor=edge_colors[i],color=colors[i%5], hatch=hatch[i%4])

    # Setting x-ticks to be in the middle of each group and adjusting font size
    mid_positions = [(a + b) / 2 for a, b in zip(bar_positions[0], bar_positions[-1])]
    ax.set_xticks(mid_positions)
    ax.set_xticklabels(cluster_labels, fontsize=font_size)
    # Adjusting y-tick font size
    ax.tick_params(axis='y', labelsize=font_size)

def customize_plot(ax, x_label, y_label, title, font_size, legend_pos,y_lim=[80,140]):
    ax.set_xlabel(x_label, fontsize=font_size)
    ax.set_ylabel(y_label, fontsize=font_size)
    ax.set_title(title, fontsize=font_size)
    ax.legend(loc=legend_pos, prop={'size': 11},columnspacing=0.5, bbox_to_anchor=(0.5, 1.35), ncol=2)

def plot_chart(groups, x_label, y_label, cluster_labels, title="", font_size=12, legend_pos='upper center'):
    group_labels, values = prepare_data(groups)
    fig, ax = plt.subplots(figsize=(4, 3))
    create_bars(ax, group_labels, values, cluster_labels, bar_width=0.35, font_size=font_size)
    customize_plot(ax, x_label, y_label, title, font_size, legend_pos)
    fig = plt.gcf()
    left = max(fig.subplotpars.left, 1 - fig.subplotpars.right)
    bottom = max(fig.subplotpars.bottom, 1 - fig.subplotpars.top)
    fig.subplots_adjust(left=left, right=1 - left, bottom=bottom, top=1 - bottom)
    plt.tight_layout()
    plt.show()


def convertLegible(groups,cluster_labels):
    new_groups={}
    test_list=[]
    for item in groups:
        test_list.append(item)
    for x in range(0,len(cluster_labels)):
        ex_list=[]
        for item in test_list:
            ex_list.append(groups[item][x])
        new_groups[cluster_labels[x]] = ex_list
    return new_groups,test_list


# Example usage
groups1 = {
    "No HP": [0.255,0.562],
    "Standard HP": [0.250 ,0.543 ],
    "Always on HP":[0.207,0.452 ],
    "Clumped(Half)":[0.237,0.555 ],
    "Clumped(Quarter)":[0.245 ,0.652 ],
    "CFS+Idle":[0.261 ,0.655 ],
    "Pinned+Idle":[0.110,0.295]
}



def normalize_to_positive(asdf):
    for key in asdf:
        
        norm = groups[key][0]
        for z in range(0,len(groups[key])):
            groups[key][z]=norm/groups[key][z] * 100

cluster_labels1 = ["Mean","95"]
cluster_labels = ["No HP","Standard HP","Always on HP","Clumped(Half)","Clumped(Quarter)","CFS+Idle","Pinned+Idle"]


groups, cluster_labels= convertLegible(groups,cluster_labels)

plot_chart(groups, x_label='', y_label='Latency(ms)', cluster_labels=cluster_labels)
