import matplotlib.pyplot as plt
edge_colors=['red','green','blue']
colors=['none','none','blue']
hatch = ['/', 'x', 'o'] 
# List of edge colors
edge_colors = ['b', 'g', 'r', 'c', 'm', 'y', 'k', 'w', 'orange', 'purple']

# List of fill colors
fill_colors = ['none', 'none', 'none', 'none', 'none', 'gray', 'olive', 'gold', 'silver', 'maroon']

# List of hatch patterns
hatch_patterns = ['/', '\\', '.', '-', '+', 'x', '*', 'o', 'O', '.']

def prepare_data(groups):
    # Preparing data for plotting
    labels = list(groups.keys())
    values = [groups[label] for label in labels]
    return labels, values

def create_bars(ax, group_labels, values, cluster_labels, bar_width=0.18, font_size=12):
    n_groups = len(values[0])
    bar_positions = []
    for i, group_values in enumerate(values):
        positions = [x*(bar_width*6 + 0.4) + bar_width*i for x in range(n_groups)]
        bar_positions.append(positions)
        print(positions)
        ax.bar(positions, group_values, bar_width, label=group_labels[i],edgecolor=edge_colors[i],color=fill_colors[i], hatch=hatch_patterns[i])

    # Setting x-ticks to be in the middle of each group and adjusting font size
    mid_positions = [(a + b) / 2 for a, b in zip(bar_positions[0], bar_positions[-1])]
    ax.set_xticks(mid_positions)
    ax.set_xticklabels(cluster_labels, fontsize=font_size)
    # Adjusting y-tick font size
    ax.tick_params(axis='y', labelsize=font_size)

def customize_plot(ax, x_label, y_label, title, font_size, legend_pos,y_lim=[0,110]):
    ax.set_xlabel(x_label, fontsize=font_size)
    ax.set_ylabel(y_label, fontsize=font_size)
    ax.set_title(title, fontsize=font_size)
    if y_lim:
        ax.set_ylim(y_lim)
    ax.legend(loc=legend_pos, prop={'size': 11},columnspacing=0.1, bbox_to_anchor=(0.5, 1.35), ncol=3)

def plot_chart(groups, x_label, y_label, cluster_labels, title="", font_size=12, legend_pos='upper center'):
    group_labels, values = prepare_data(groups)
    fig, ax = plt.subplots(figsize=(4.7, 3.2))
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
    "masstree": [50.5, 26.4, 25.9,14.6,9,5.1],
    "img-dnn": [2084.140,68.570,37.005,19.014,15.246,6.765],
    "Xapian":[27.547,26.518,19.907,17.038,11.088,5.814],
    "specjbb":[23.740,20.216,16.247,12.568,8.728,4.761]
}

groups = {
    "masstree": [14.339 , 9.314 , 9.624 ,12.181,20.972,12.524],
    "img-dnn": [304.978,21.073,10.507,5.565,4.631,2.154],
    "xapian": [9.403,9.127,6.968,9.116,4.158,1.857],
    "specjbb":[4.684,5.086,4.195,3.685,2.832,1.683]
}

def performNormalize(in_group):
    for item in in_group:
        norm=in_group[item][0]
        for x in range(0,len(in_group)):
            in_group[item][x]=in_group[item][x]/norm*100

performNormalize(groups)

cluster_labels = ["24ms", "20ms", "16ms","12ms","8ms","4ms"]

groups, cluster_labels= convertLegible(groups,cluster_labels)

plot_chart(groups, x_label='', y_label='Latency(% normalized)', cluster_labels=cluster_labels)
