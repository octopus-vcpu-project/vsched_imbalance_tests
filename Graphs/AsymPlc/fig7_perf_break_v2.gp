set terminal postscript eps enhanced color "NimbusSanL-Regu, 24" fontfile "/usr/share/texlive/texmf-dist/fonts/type1/urw/helvetic/uhvr8a.pfb"
set output 'fig7_perf_break_v2.eps'
set boxwidth 0.75 absolute
#set style fill   solid 1.00 border lt -1
set border -1
set border -1 front lt black linewidth 1.000 dashtype solid
set style fill solid 2 border -1
set grid nopolar
set grid noxtics nomxtics ytics nomytics noztics nomztics nortics nomrtics \
 nox2tics nomx2tics noy2tics nomy2tics nocbtics nomcbtics
set grid layerdefault   lt 0 linecolor 0 linewidth 0.500,  lt 0 linecolor 0 linewidth 0.500
#set key outside right top vertical Left reverse noenhanced autotitle columnhead box lt black linewidth 1.000 dashtype solid
set key left top font "Times New Roman,35" at 0.1,135,0 spacing 1 maxrow 2
#set key width -17 #tune key horizonital spacing
set style histogram columnstacked title textcolor lt -1
set datafile missing '-'
set style data histograms
#set xtics border in scale 1,0.5 nomirror norotate  autojustify
set xtics border in scale 1,0.5 nomirror rotate by -45  autojustify
#set xtics  norangelimit 
set xtics font "Times New Roman,35"
set xtics   ()
set ytics border in scale 0,0 mirror norotate  autojustify
set ytics  font "Times New Roman,35"
set xrange [-0.5:8.6]
set ylabel "Normalized throughput (%)" font "Times New Roman,35" offset 0.7,-0.7,0 
set yrange [0:135]

set size 1.0, 1.0

set bmargin 7
set lmargin 7
set tmargin 0.9
set rmargin 1.6



plot 'fig7_perf_break_v2.dat' using 2 ti col, \
	'' using 3 ti col, \
	'' using 4 ti col, \
	'' using 5 ti col, \
	'' using 6 ti col, \
	'' using 7 ti col, \
	'' using 8 ti col, \
	'' using 9 ti col, \
	'' using 10:key(1) ti col
