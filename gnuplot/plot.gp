reset

set output "`echo $gp_d-$gp_m`.eps" # (output to any filename you use)
# set output "`echo $gp_d-$gp_m`.png" # (output to any filename you use)
set term postscript eps enhanced # will produce eps output
#set term png             # (will produce .png output)

set   autoscale                        # scale axes automatically
unset log                              # remove any log-scaling
unset label                            # remove any previous labels
set xtic auto font "Times-Roman, 24"   # set xtics automatically
set ytic auto font "Times-Roman, 24"   # set ytics automatically
set yr [0.6:0.9]
set title "`echo $gp_t`" font "Times-Roman bold, 36"
set xlabel "Minimum Frequency" font "Times-Roman bold, 24" 
set ylabel "Accuracy (%)" font "Times-Roman bold, 24"
set key spacing 1.5
set pointsize 10
set pointsize 1.5

plot '<cat $gp_f | grep $gp_d | grep $gp_m | grep aromatic_variant' using 3:4 title "{/Times=24 Aromatic}" with linespoints pt 4, '<cat $gp_f | grep $gp_d | grep $gp_m | grep kekule_variant' using 3:4 title "{/Times=24 Kekule}" with linespoints pt 5, '<cat $gp_f | grep $gp_d | grep $gp_m | grep reduced_variant' using 3:4 title "{/Times=24 Reduced}" with linespoints pt 3
rep

set term X11
set output 


