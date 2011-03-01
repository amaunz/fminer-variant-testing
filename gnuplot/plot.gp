set   autoscale                        # scale axes automatically
unset log                              # remove any log-scaling
unset label                            # remove any previous labels
set xtic auto                          # set xtics automatically
set ytic auto                          # set ytics automatically
set yr [0.6:0.9]

set title "`echo $gp_d`"
set xlabel "Minimum Frequency"
set ylabel "Accuracy (%)"

set term png             # (will produce .png output)
set output "`echo $gp_d-$gp_m`.png" # (output to any filename you use)


plot '<cat $gp_f | grep $gp_d | grep $gp_m | grep aromatic_variant' using 3:4 title 'Aromatic' with linespoints pt 3, '<cat $gp_f | grep $gp_d | grep $gp_m | grep kekule_variant' using 3:4 title 'Kekule' with linespoints pt 4, '<cat $gp_f | grep $gp_d | grep $gp_m | grep reduced_variant' using 3:4 title 'Reduced' with linespoints pt 5

