#set terminal postscript eps enhanced "NimbusSanL-Regu, 20" fontfile "/usr/share/fonts/type1/texlive-fonts-recommended/uhvr8a.pfb"
set terminal postscript eps enhanced color "NimbusSanL-Regu, 24" fontfile "/Users/morewrong/Downloads/uhvr8a.pfb"

set output "micro-motivate.eps"

set size 1.0,1.0
set multiplot
#set xtics font "Times New Roman, 25" nomirror offset 0,0 rotate by -5
set xtics font "Times New Roman, 35" nomirror offset 0,0 rotate by 0
set ytics nomirror

# plot A
set ylabel "Normalized throughput (%)\n" font "Times New Roman,35" offset 0,0
set style fill solid 1.00 border 0
set style data histogram
set style histogram clustered gap 1
#set style histogram errorbars gap 1 lw 1
set key inside right top font "Times New Roman,35"

set key title "Scheduling Strategies"
set yrange [1000:4000]
set origin 0.0,0.15
set size 1.0,0.85
#set label 11 center at graph 0.5,-0.48 "(a) KVM Hypervisor" font "Times New Roman,35"
#set xtics ("Hbase" 0, "PageRank" 1, "MongoDB" 3, "Kmeans" 4)
set xtics font "Times New Roman,35"
set ytics font "Times New Roman,35"
set xtics ("Assymetric" 0, "Symmetric" 2)
#set xtics ("p.dedup" 0, "s.volrend" 1)
set bmargin 0
set lmargin 9.5
set rmargin 0.9

plot "micro-motivate.dat" using 2 title "CFS" linecolor rgb "red" lt 1 fs pattern 3, \
		 '' using 3 title "CFS+vProbing" linecolor rgb "black" lt 1 fs pattern 6, \
		 '' using 4 title "CFS+Pinning" linecolor rgb "blue" lt 1 fs pattern 9, \
		 100 notitle lc rgb"black"
unset style

#plot "breakdown.dat" using ($3/$2*100) title "RASS and RCR" linecolor rgb "purple" lt 1 fs pattern 9, \
		 '' using ($4/$2*100) title "LTCR" linecolor rgb "#c7e9c0" lt 1 fs pattern 3, \
		 '' using ($5/$2*100) title "vSMT-IO" linecolor rgb "#238b45" lt 1 fs pattern 3, \
		 100 notitle lc rgb"black"
unset style

#plot "breakdown.dat" using ($3/$2*100) title "Unbalancer and xResolver" linecolor rgb "purple" lt 1 fs pattern 9, \
		 '' using ($4/$2*100) title "xWait" linecolor rgb "#c7e9c0" lt 1 fs pattern 3, \
		 '' using ($5/$2*100) title "vSMT-IO" linecolor rgb "#238b45" lt 1 fs pattern 3, \
		 100 notitle lc rgb"black"
unset style

# plot B
#set ylabel "Execution Time (Seconds)" font "Times New Roman,30" offset 0,-2
#set key left top font "Times New Roman,35" at 1.25,139,0
#set style fill solid 1.00 border 0
#set style data histogram
#set style histogram rowstacked gap 1
#set boxwidth 0.5
#set style data histogram
#set style histogram errorbars gap 1 lw 1
#set yrange [0:139]
#set origin 1.0,0.15
#set size 1.0,0.85
#set label 11 center at graph 0.5,-0.48 "(b) XEN Hypervisor" font "Times New Roman,35"
#set label 11 center "(b) XEN Hypervisor" font "Times New Roman,35"
#set xtics ("HDFS" 0, "PageRank" 1, "MongoDB" 3, "Kmeans" 4)

#plot "motivate2_v2.dat" using 3:2:4 title "Vanilla XEN" linecolor rgb "yellow" lt 1 , \
	 '' using 6:5:7 title "w/ vSMT-IO" linecolor rgb "red" lt 1, \
		 100 notitle lc rgb"black"
#unset style
#unset boxwidth
#unset xtics
#unset ytics

# plot C
#set ylabel "I/O Bandwidth (MB/s)" font "Times New Roman,30"
#set key left top font "Times New Roman,35" at -2.15,139,0
#set style fill solid 1.00 border 0
#set style data histogram
#set style histogram clustered gap 1
#set key left top font "Times New Roman,25" at 0.65,170,0
#set yrange [0:170]
#set style data histogram
#set style histogram errorbars gap 1 lw 1
#set yrange [0:139]
#set origin 2.0,0.15
#set size 1.0,0.85
#set label 11 center at graph 0.6,-0.48 "(c) Commertial Hypervisor" font "Times New Roman,35"
#set xtics ("HDFS" 0, "PageRank" 1, "MongoDB" 3, "Kmeans" 4)

#plot "motivate3_v2.dat" using 3:2:4 title "Vanilla Commertial Hyperv." linecolor rgb "yellow" lt 1 , \
	 '' using 6:5:7 title "w/ vSMT-IO" linecolor rgb "red" lt 1, \
		 100 notitle lc rgb"black"
#unset style
#set size 1.0,0.85
#set label 11 center at graph 0.5,-0.18 "(c) Fairness of I/O Scheduler" font "Times New Roman,30"

#plot "motivate3_v2.dat" using 2:xtic(1) title "I/O-bound task 1" linecolor rgb "yellow" lt 1, '' using 3 title "I/O-bound task 2" linecolor rgb "red" lt 1
#unset style

# plot C
#set ylabel "I/O Bandwidth (MB/s)" font "Times New Roman,30"
#set style fill solid 1.00 border 0
#set style data histogram
#set style histogram clustered
#set key left top font "Times New Roman,25"
#set boxwidth 0.5
#set yrange [0:160]
#set origin 2.0,0.15
#set size 1.0,0.85
#set label 11 "(c) fairness of I/O scheduler" font "Times New Roman,30"
#
#plot "motivate3.dat" using 2:xtic(1) title "I/O workload 1" linecolor rgb "yellow" lt 1, '' using 3 title "I/O workload 2" linecolor rgb "red" lt 1
#unset style

#set size 3.0,2.70

#set style line 1 lt 3 lc rgb '#FF0000' lw 5
#set style line 2 lt 1 lc rgb '#EBEBEB' lw 1
#set style line 3 lt 1 lw 4
#set output "fig6_vary.eps"

#set nokey

#set ylabel "Normalized Speed (ops)" font "Times New Roman,30" offset 0, -1
#set xlabel "Time (sec)" font "Times New Roman,30" offset 0,0
#set xrange [0:8]
#set xtics nomirror 1 font "Times New Roman, 25" 
#set mxtics 2
#set yrange [0:100]
#set ytics format "" font "Times New Roman, 25"
#set ytics nomirror
#set ytics 20
#set ytics add ("0" 0, "10" 10, "20" 20, "30" 30, "40" 40, "50" 50, "60" 60, "70" 70, "80" 80, "90" 90, "100" 100)
#set xtics add ("0" 0, "100" 1, "200" 2, "300" 3, "400" 4, "500" 5, "600" 6, "700" 7, "800" 8, "900" 9, "1000" 10)
#set mytics 2 

# Draw only the left and bottom borders: 
#set border 3
#set key left top font "Times New Roman,25" at 4.09,100,0
#set label 11 center at graph 0.49,-0.31 "(c) Performance Variation" font "Times New Roman,30"

#set origin 2.0,0.15
#set size 1.0,0.85
#set label 11 center at graph 0.5,-0.18 "(a) Failover 1" font "Times New Roman,25"

#plot 'fig6_vary.dat' using 1:2 title "Vanilla" with line ls 3, '' using 3 title "Heterogenous" with line ls 1

#unset yrange
#unset ytics
#unset border
