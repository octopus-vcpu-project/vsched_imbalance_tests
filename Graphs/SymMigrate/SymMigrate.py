import glob
import matplotlib.pyplot as plt

def get_correct_range(v):
    normal_len=40
    correction_factor=300
    corrective_factor = normal_len/(len(v)-1)
    g=[]
    for x in range(0,len(v)):
        g.append(x*corrective_factor)
    return g

def graph_lst(pin_cs,smrt_cs,nve_cs):
    plt.figure(figsize=(4, 3))
    for k, v in nve_cs.items():
        plt.plot(get_correct_range(v), v,linestyle="--",color='blue',label="CFS")
    for k, v in smrt_cs.items():
        plt.plot(get_correct_range(v), v, linestyle="-",color='red',label="CFS+Vprober")
    handles, labels = plt.gca().get_legend_handles_labels()
    plt.ylabel("Nr of Migrations", fontsize=14)
    plt.xlabel("Time(Seconds)", fontsize=14)
    by_label = dict(zip(labels, handles))
    plt.legend(by_label.values(), by_label.keys(),prop={'size': 12}) # To draw legend
    plt.tight_layout()
    plt.show()


biggest=-99999999999

nve_cs={'2175': [16.0, 31.0, 42.0, 57.0, 69.0, 82.0, 93.0, 105.0, 116.0, 126.0, 135.0, 145.0, 167.0, 180.0, 191.0, 202.0, 212.0, 222.0], '2176': [18.0, 28.0, 40.0, 53.0, 65.0, 75.0, 85.0, 97.0, 113.0, 126.0, 137.0, 147.0, 157.0, 168.0, 179.0, 190.0, 199.0, 210.0], '2177': [14.0, 24.0, 35.0, 46.0, 56.0, 70.0, 81.0, 90.0, 101.0, 112.0, 122.0, 136.0, 147.0, 158.0, 170.0, 182.0, 192.0, 203.0], '2178': [28.0, 39.0, 53.0, 62.0, 74.0, 85.0, 96.0, 108.0, 119.0, 131.0, 142.0, 153.0, 163.0, 173.0, 185.0, 198.0, 210.0, 227.0]} 
smrt_cs={'3721': [21.0, 35.0, 45.0, 48.0, 48.0, 48.0, 48.0, 49.0, 49.0, 49.0, 50.0, 50.0, 50.0, 50.0, 51.0, 51.0, 51.0, 51.0], '3722': [22.0, 33.0, 42.0, 48.0, 48.0, 48.0, 48.0, 51.0, 51.0, 51.0, 54.0, 54.0, 54.0, 54.0, 54.0, 54.0, 54.0, 54.0], '3723': [23.0, 34.0, 44.0, 48.0, 48.0, 48.0, 48.0, 52.0, 52.0, 52.0, 53.0, 54.0, 54.0, 54.0, 56.0, 56.0, 56.0, 56.0], '3724': [30.0, 42.0, 52.0, 55.0, 55.0, 55.0, 55.0, 58.0, 58.0, 58.0, 61.0, 62.0, 62.0, 62.0, 63.0, 63.0, 63.0, 63.0]}

nve_iterator=0
for item in nve_cs:
    nve_iterator+=nve_cs[item][-1]
s_iterator=0
for item in smrt_cs:
    s_iterator+=smrt_cs[item][-1]
print('nve iterator',nve_iterator)
print('s iterator',s_iterator)

graph_lst(0,smrt_cs,nve_cs)