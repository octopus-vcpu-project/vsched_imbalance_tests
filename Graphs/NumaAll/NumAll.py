import matplotlib.pyplot as plt
edge_colors=['red','green','blue',"grey","yellow","orange"]
colors=['none','none','blue',"none","none","none"]
hatch = ['/', 'x', 'o',"//","-","."] 
def prepare_data(groups):
    # Preparing data for plotting
    labels = list(groups.keys())
    values = [groups[label] for label in labels]
    return labels, values

def create_bars(ax, group_labels, values, cluster_labels, bar_width=0.08, font_size=22):
    n_groups = len(values[0])
    print("no groups",n_groups)
    bar_positions = []
    for i, group_values in enumerate(values):
        positions = [x*(bar_width*6 + 0.2) + bar_width*i for x in range(n_groups)]
        bar_positions.append(positions)
        print(positions)
        ax.bar(positions, group_values, bar_width, label=group_labels[i%3],edgecolor=edge_colors[i%3],color=colors[i%3], hatch=hatch[i%3])

    # Setting x-ticks to be in the middle of each group and adjusting font size
    mid_positions = [a+(bar_width) for a, b in zip(bar_positions[0], bar_positions[-1])]
    mid_positions1 = [b-(bar_width)  for a, b in zip(bar_positions[0], bar_positions[-1])]
    mid_positions = mid_positions1 + mid_positions
    mid_positions.sort()
    real_cluster_labels=[]
    i=0
    for x in cluster_labels:
        real_cluster_labels.append(x+" w/ CFS")
        real_cluster_labels.append(x+ " w/ vProbing")
    print("this is zip bar positions",zip(bar_positions[0], bar_positions[-1]))
    ax.set_xticks(mid_positions)

    plt.text(bar_positions[5][0]-0.12, 4, f'{1.08}',rotation=-20,ha='left',fontsize=font_size)
    ax.set_xticklabels(real_cluster_labels, fontsize=font_size)
    # Adjusting y-tick font size
    ax.tick_params(axis='y', labelsize=font_size)

def customize_plot(ax, x_label, y_label, title, font_size, legend_pos,y_lim=[0,180]):
    ax.set_xlabel(x_label, fontsize=font_size)
    ax.set_ylabel(y_label, fontsize=font_size)
    ax.set_title(title, fontsize=font_size)
    if y_lim:
        ax.set_ylim(y_lim)
    ax.legend(loc=legend_pos, prop={'size': 14},columnspacing=0.5, bbox_to_anchor=(0.5, 1.35), ncol=2)

def plot_chart(groups, x_label, y_label, cluster_labels, title="", font_size=22, legend_pos='upper center'):
    group_labels, values = prepare_data(groups)
    fig, ax = plt.subplots(figsize=(12, 6))
    create_bars(ax, group_labels, values, cluster_labels, bar_width=0.35, font_size=font_size)
    customize_plot(ax, x_label, y_label, title, font_size, legend_pos)
    fig = plt.gcf()
    left = max(fig.subplotpars.left, 1 - fig.subplotpars.right)
    bottom = max(fig.subplotpars.bottom, 1 - fig.subplotpars.top)
    plt.xticks(rotation=-20,ha='left')
    fig.subplots_adjust(left=left, right=1 - left, bottom=bottom, top=1 - bottom)
    handles, labels = plt.gca().get_legend_handles_labels()
    
    by_label = dict(zip(labels, handles))
    plt.legend(by_label.values(), by_label.keys(),prop={'size': 15}) 
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
groups = {
    "Ngninx": [7856.89, 2.43, 270060, 10185.32,3.26,2939],
    "Dedup": [1, 1.27,1091060,1.56824009079, 1.30, 721983],
    "Hackbench": [1, 0.46,6118168,1.194, 0.49, 3500155],
}


for das in groups:
    for x in range(0,3):
        groups[das][x+3]=groups[das][x+3]/groups[das][x]*100
        groups[das][x]=100
print(groups)


cluster_labels = ["Throughput", "IPC", "IPI","Thoroughputd", "IPCd", "Ipisd"]

groups, cluster_labels= convertLegible(groups,cluster_labels)

plot_chart(groups, x_label='', y_label="Normalized throughput (%)\n(relative to CFS)", cluster_labels=cluster_labels)
