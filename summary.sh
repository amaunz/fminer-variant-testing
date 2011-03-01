#!/bin/bash
#
# Creates summary of accuracies for variants "", "-a", "-nob"
# DO NOT RE-INDENT! USES Internal Field Separator!

i=1

if [ $# -ne 2 ]; then
	echo "Synopsis: $0 <input_dir> \"endpoint_array\""
	echo "Example: $0 `pwd`/110228-172254 \"salmonella_mutagenicity rat_carcinogenicity_alt mouse_carcinogenicity_alt multi_cell_call_alt\" (mind the \"\")"
	exit 1
fi

INPUT_DIR=$1
ENDPOINT_ARR=( `echo "$2"` )

if [ ! -d $INPUT_DIR ]; then
	echo "Directory '$INPUT_DIR' not found!"
	exit
fi

for d in "${ENDPOINT_ARR[@]}"; do 
	OLDIFS=$IFS
export IFS="
"
	for v in "" "-a" "-nob"; do 
		for f in `seq 1 50`; do 
			fn="$INPUT_DIR/$d*-f$f$v.summary"; 
			lc=$(grep "accuracy" $fn 2>/dev/null ); 

			if [ $? -eq 0 ]; then # file was found
				for field in $lc; do
					var=""
					case "$v" in
						"") var="aromatic_variant";;
						"-a") var="kekule_variant";;
						"-nob") var="reduced_variant";;
					esac
					l=`echo "$field" | sed "s/.*accuracy.*\ /\'$d\'	\'$var\'	$f	/g"`
					if [ $i -eq 4 ]; then 
						i=1
					fi
					echo -n "$l	"
					case "$i" in
						1) echo "'wt_eval'" ;;
						2) echo "'ad_eval'" ;; 
						3) echo "'all_eval'";;
					esac
					i=$(($i+1))
				done
			fi
		done
	done
	export IFS=$OLDIFS
done
