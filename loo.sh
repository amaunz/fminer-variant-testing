#!/bin/bash

# export everything to newly created subshells
set -a 

export FMINER_LAZAR="1"
export FMINER_SMARTS="1"
export R_HOME="/usr/lib/R"
export LDFLAGS="/usr/lib/R/lib/"

NICE="nice -n 19"
RUBY="ruby1.8"
FMINER="$NICE /home/maunza/fminer2/fminer/fminer /home/maunza/fminer2/libbbrc/libbbrc.so"
LAZAR="$NICE /home/maunza/lazar-core/lazar"
L2S="$NICE $RUBY /home/maunza/lazar-core/loo2summary.rb"
COVERAGE="$NICE $RUBY /home/maunza/xvalgenerator/coverage.rb"
MCC="/home/maunza/cpdbdata/multi_cell_call/multi_cell_call_alt.smi /home/maunza/cpdbdata/multi_cell_call/multi_cell_call_alt.class"
SALM="/home/maunza/cpdbdata/salmonella_mutagenicity/salmonella_mutagenicity_alt.smi /home/maunza/cpdbdata/salmonella_mutagenicity/salmonella_mutagenicity_alt.class"
RAT="/home/maunza/cpdbdata/rat_carcinogenicity/rat_carcinogenicity_alt.smi /home/maunza/cpdbdata/rat_carcinogenicity/rat_carcinogenicity_alt.class"
MOC="/home/maunza/cpdbdata/mouse_carcinogenicity/mouse_carcinogenicity_alt.smi /home/maunza/cpdbdata/mouse_carcinogenicity/mouse_carcinogenicity_alt.class"
MCC_NOB="/home/maunza/cpdbdata/multi_cell_call/multi_cell_call_alt.nob.smi /home/maunza/cpdbdata/multi_cell_call/multi_cell_call_alt.class"
SALM_NOB="/home/maunza/cpdbdata/salmonella_mutagenicity/salmonella_mutagenicity_alt.nob.smi /home/maunza/cpdbdata/salmonella_mutagenicity/salmonella_mutagenicity_alt.class"
RAT_NOB="/home/maunza/cpdbdata/rat_carcinogenicity/rat_carcinogenicity_alt.nob.smi /home/maunza/cpdbdata/rat_carcinogenicity/rat_carcinogenicity_alt.class"
MOC_NOB="/home/maunza/cpdbdata/mouse_carcinogenicity/mouse_carcinogenicity_alt.nob.smi /home/maunza/cpdbdata/mouse_carcinogenicity/mouse_carcinogenicity_alt.class"

FLOAT="$HOME/bin/float.sh"

# Call with (f,a,db) 
fminer() 
{ 
	local f=$1
	local a=$2
	local db=$3
	local var=$4
	local name=`echo "$d" | sed 's/\ .*//g' | sed 's/.*\///g' | sed 's/\.smi//g' | sed "s/\.$var//g"`

	local fminer_cmd="$FMINER $f $a $db $d" 
	db=`echo $db | sed 's/\ //g'`

	local frags="$name$f$a$db.frag"
	if [ ! $var = "" ]; then
		frags="$name$f$a$db-$var.frag"
	fi

	if [ ! -e $DESTDIR/$frags ]; then
		echo $fminer_cmd
		eval "$fminer_cmd > $DESTDIR/$frags";
	fi

	local loo="$(echo $frags | sed 's/\.frag/\.loo/g')"
	local summ="$(echo $frags | sed 's/\.frag/\.summary/g')"
	lazar $loo $frags $summ
}

# Call with (loofile, fragsfile)
lazar()
{
	local loo=$1
	local frags=$2
	local summ=$3
	local smi=`echo "$d" | sed 's/\ .*//g'`
	local class=`echo "$d" | sed 's/.*\ //g'`

	local lazar_cmd="$LAZAR -s $smi -t $class -f $DESTDIR/$frags -x > $DESTDIR/$loo" 
	if [ ! -f $DESTDIR/$loo ]; then
		echo $lazar_cmd
		eval "$lazar_cmd";
	fi
	local sum_cmd="$L2S $DESTDIR/$loo $DESTDIR/$summ"
	if [ ! -f $DESTDIR/$summ ]; then
		echo $sum_cmd
		eval "$sum_cmd"
	fi
}

# Call with (n,p): sets f
prom()
{
	local n=$1 ; local p=$2
	echo `float_eval "$n * $p / 1000" | sed 's/\..*//g'`
}

# Call with (frags-file)
coverage()
{
	local frags_file=$1
	echo `$COVERAGE $frags_file`
}

fminer_loop()
{

	# loop over for different promille values
	local p=0
	local dataset_variant=$1
	for p in 6 7 8 10 20 40; do
		local smi=`echo "$d" | sed 's/\ .*//g'`
		local n=`cat $smi | wc -l`
		local f=`prom $n $p` # calculate frequency in promille
		if [ -n $f ]; then
			if [ $f -gt 1 ]; then
				fminer  "-f$f"    ""      ""		"$dataset_variant" # pass through ds variant
				fminer  "-f$f"    "-a"    ""		"$dataset_variant"
				#fminer  "-f$f"    ""      "-d -b"	"$dataset_variant"
				#fminer  "-f$f"    "-a"    "-d -b"	"$dataset_variant"

			else
				echo "f: '$f'"
			fi
		fi

	done

}


linkdest=""
if [ $# -gt 0 ]; then
	linkdest=$1
	if [ ! -d $linkdest ]; then
		echo "Linkdest not found!"
		exit
	fi
fi

rm nohup.out
source $FLOAT
DESTDIR=`date +%y%m%d-%H%M%S`


# CREATE LOCAL DESTDIR
mkdir $DESTDIR 
if [ ! -z $linkdest ]; then
	ln -s $linkdest/* $DESTDIR/
fi


for d in "$MCC" "$RAT" "$MOC" "$SALM"; do
	nohup bash -c "fminer_loop \"\"" &
done
for d in "$MCC_NOB" "$RAT_NOB" "$MOC_NOB" "$SALM_NOB"; do
	nohup bash -c "fminer_loop \"nob\"" &
done

