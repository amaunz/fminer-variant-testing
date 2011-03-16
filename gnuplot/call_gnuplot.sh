#!/bin/bash
#
# Plots summary of accuracies
# one plot per evaluation methods ad, wt, all

GNUPLOT=$(which gnuplot)

if [ $# -lt 3 ]; then
  echo "Synopsis: $0 <gnuplot code file> <summary file> \"endpoint_array\""
  echo "Example: $0 plot.gp 110228-172254/summ.txt \"salmonella_mutagenicity rat_carcinogenicity_alt mouse_carcinogenicity_alt multi_cell_call_alt\" (mind the \"\")"
  exit 1
fi

GNUPLOT_SCRIPT=$1
SUMMARY_FILE=$2
ENDPOINT_ARR=$3

if [ ! -f $GNUPLOT_SCRIPT -a -f $SUMMARY_FILE ]; then
  echo "File does not exist!"
  exit 1
fi

export gp_f=$SUMMARY_FILE

for d in $ENDPOINT_ARR; do 
  echo $d

  for lstsm in "msa" "nls" "nop"; do
    echo -n "$lstsm: "
  
    export gp_lstsm=$lstsm
    export gp_d=$d
    export gp_t=""
  
    case $gp_d in 
      "salmonella_mutagenicity" )
        export gp_t="Salmonella Mutagenicity";;
      "rat_carcinogenicity_alt" )
        export gp_t="Rat Carcinogenicity";;
      "mouse_carcinogenicity_alt" )
        export gp_t="Mouse Carcinogenicity";;
      "multi_cell_call_alt" )
        export gp_t="Multicell Call";;
    esac

    for m in ad_eval wt_eval all_eval; do 
      echo -n "$m "
      export gp_m=$m
      $GNUPLOT $GNUPLOT_SCRIPT
    done

  done
  echo

done

