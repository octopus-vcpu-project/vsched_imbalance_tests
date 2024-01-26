from scipy.stats.kde import gaussian_kde
from numpy import linspace
import matplotlib.pyplot as plt
import numpy as np
font_size=11
def plotPDF(counts1, values1, color):
    data = [value for value, count in zip(values1, counts1) for _ in range(count)]
    kde = gaussian_kde(data)
    dist_space = linspace(min(data), max(data), len(values1) * 5)
    plt.plot(dist_space, kde(dist_space), color=color)
    plt.fill_between(dist_space, kde(dist_space), color=color, alpha=0.5)
fig, ax = plt.subplots(figsize=(4, 3))
ax.set_xlabel("Number of Active pCPUs", fontsize=font_size)
ax.set_ylabel("%Chance", fontsize=font_size)
plotPDF([1, 11, 21, 26, 18, 4], [9, 10, 11, 12, 13, 14], 'blue')
plotPDF([1, 27, 53], [10, 15, 16], 'red')
plt.tight_layout()
plt.show()