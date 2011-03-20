#!/bin/bash

# export everything to newly created subshells
set -a 

export FMINER_LAZAR="1"
export FMINER_SMARTS="1"

#source $HOME/.bash_ob
#source $HOME/.bash_r
#source $HOME/.bash_ruby
#source $HOME/.bash_gems

NICE="nice -n 19"
RUBY="/usr/bin/ruby1.8"
FMINER="$NICE $HOME/validations/fminer2/fminer/fminer $HOME/validations/fminer2/liblast/liblast.so"
LAZAR="$NICE $HOME/validations/lazar-core/lazar"
L2S="$NICE $RUBY $HOME/validations/lazar-core/loo2summary.rb"
COVERAGE="$NICE $RUBY $HOME/validations/xvalgenerator/coverage.rb"
LU="$NICE $RUBY $HOME/validations/last-utils/last-utils.rb"
FLOAT="$HOME/bin/float.sh"
DATE="`date +%y%m%d-%H%M%S`"
LASTDIR="$HOME/validations/last_variant_testing"
DESTDIR="$LASTDIR/$DATE"
OUTFILE="$LASTDIR/loo-output-$LOODATA-m25-$DATE.txt"
PIDFILE="$LASTDIR/loo-output-$LOODATA-m25-$DATE.pid"

MCC="$HOME/validations/cpdbdata/multi_cell_call/multi_cell_call_alt.smi $HOME/validations/cpdbdata/multi_cell_call/multi_cell_call_alt.class"
SALM="$HOME/validations/cpdbdata/salmonella_mutagenicity/salmonella_mutagenicity_alt.smi $HOME/validations/cpdbdata/salmonella_mutagenicity/salmonella_mutagenicity_alt.class"
RAT="$HOME/validations/cpdbdata/rat_carcinogenicity/rat_carcinogenicity_alt.smi $HOME/validations/cpdbdata/rat_carcinogenicity/rat_carcinogenicity_alt.class"
MOC="$HOME/validations/cpdbdata/mouse_carcinogenicity/mouse_carcinogenicity_alt.smi $HOME/validations/cpdbdata/mouse_carcinogenicity/mouse_carcinogenicity_alt.class"
MCC_NOB="$HOME/validations/cpdbdata/multi_cell_call/multi_cell_call_alt.nob.smi $HOME/validations/cpdbdata/multi_cell_call/multi_cell_call_alt.class"
SALM_NOB="$HOME/validations/cpdbdata/salmonella_mutagenicity/salmonella_mutagenicity_alt.nob.smi $HOME/validations/cpdbdata/salmonella_mutagenicity/salmonella_mutagenicity_alt.class"
RAT_NOB="$HOME/validations/cpdbdata/rat_carcinogenicity/rat_carcinogenicity_alt.nob.smi $HOME/validations/cpdbdata/rat_carcinogenicity/rat_carcinogenicity_alt.class"
MOC_NOB="$HOME/validations/cpdbdata/mouse_carcinogenicity/mouse_carcinogenicity_alt.nob.smi $HOME/validations/cpdbdata/mouse_carcinogenicity/mouse_carcinogenicity_alt.class"

YO="$HOME/validations/ofsdata/yoshida.smi $HOME/validations/ofsdata/yoshida.class"
NCTRER="$HOME/validations/ofsdata/nctrer.smi $HOME/validations/ofsdata/nctrer.class"
BBB="$HOME/validations/ofsdata/bloodbarr.alt.smi $HOME/validations/ofsdata/bloodbarr.alt.class"
YO_NOB="$HOME/validations/ofsdata/yoshida.nob.smi $HOME/validations/ofsdata/yoshida.class"
NCTRER_NOB="$HOME/validations/ofsdata/nctrer.nob.smi $HOME/validations/ofsdata/nctrer.class"
BBB_NOB="$HOME/validations/ofsdata/bloodbarr.alt.nob.smi $HOME/validations/ofsdata/bloodbarr.alt.class"


# Call with (f,a,db,hops) 
fminer() 
{ 
	local f=$1
	local a=$2
	local db=$3
	local var=$4
	local hops=$5
	local name=`echo "$d" | sed 's/\ .*//g' | sed 's/.*\///g' | sed 's/\.smi//g' | sed "s/\.nob//g"`

	local nob=""
	if echo $d | grep "\.nob" > /dev/null; then
		nob="-nob"
	fi


	if [ -z "$nob" ] || [ -n "$a" ]; then
		local frags="$name$f$hops$a$nob$db.frag"
		local fminer_cmd="$FMINER $f $hops $a $db $d > $DESTDIR/$frags 2>/dev/null" 
		db=`echo $db | sed 's/\ //g'`
		if [ ! -e $DESTDIR/$frags ]; then
			echo "$fminer_cmd"
			if ! $dry_run ; then 
				eval "$fminer_cmd";
			fi
		fi

		local lc=0
		if [ -f $DESTDIR/$frags ]; then
			lc=`cat "$DESTDIR/$frags" | wc -l`
		fi
		if [ $lc -gt 0 ]; then
      for wcb in "wcb" "nwcb"; do
        for nna in "nna" "na"; do
          local frags2="$name$f$hops$a$nob$db-$var-$wcb-$nna.frag2"
          local frags3="$name$f$hops$a$nob$db-$var-$wcb-$nna.frag3"
          lu "$frags" "$frags2" "$frags3" "$var" "$a" "$wcb" "$nna"

          local loo="$(echo $frags3 | sed 's/\.frag3/\.loo/g')"
          local summ="$(echo $frags3 | sed 's/\.frag3/\.summary/g')"
          lazar $loo $frags3 $summ
        done
      done
		fi
	fi

}

# Call with (frags. frags2, frags3, var, a)
lu()
{
	local frags=$1
	local frags2=$2
	local frags3=$3
	local var=$4
	local a=$5
  local wcb=$6
  local nna=$7
	local smi=`echo "$d" | sed 's/\ .*//g'`

	local lu_cmd="$LU 1 $var $nna $wcb < $DESTDIR/$frags > $DESTDIR/$frags2"
	if [ ! -f $DESTDIR/$frags2 ]; then
		echo "$lu_cmd"
		if ! $dry_run ; then
			eval "$lu_cmd 2>/dev/null"
		fi
	fi
	local lu_cmd="$LU 2 $smi < $DESTDIR/$frags2 > $DESTDIR/$frags3"
	if [ ! -f $DESTDIR/$frags3 ]; then
		echo "$lu_cmd"
		if ! $dry_run ; then
			eval "$lu_cmd 2>/dev/null"
		fi
	fi
}

# Call with (loofile, fragsfile)
lazar()
{
	local loo=$1
	local frags=$2
	local summ=$3
	local smi=`echo "$d" | sed 's/\ .*//g'`
	local class=`echo "$d" | sed 's/.*\ //g'`

	local lazar_cmd="$LAZAR -s $smi -t $class -f $DESTDIR/$frags -x > $DESTDIR/$loo 2>/dev/null" 
	if [ ! -f $DESTDIR/$loo ]; then
		echo $lazar_cmd
		if ! $dry_run ; then
			eval "$lazar_cmd";
		fi
	fi
	local sum_cmd="$L2S $DESTDIR/$loo $DESTDIR/$summ"
	if [ ! -f $DESTDIR/$summ ]; then
		echo $sum_cmd
		if ! $dry_run ; then
			eval "$sum_cmd"
		fi
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
	local desc_variant=$1
  for p in `echo "$promille_arr"`; do
	#for p in 6 8 10 15 20 30 40 50 60 70 80 90 100; do
		local smi=`echo "$d" | sed 's/\ .*//g'`
		local n=`cat $smi | wc -l`
		local f=`prom $n $p` # calculate frequency in promille
		if [ -n $f ]; then
			if [ $f -gt 1 ]; then
				fminer  "-f$f"    ""      ""		"msa" 	"-m25"	      ; echo ""
				fminer  "-f$f"    "-a"    ""		"msa" 	"-m25"	      ; echo ""
				fminer  "-f$f"    ""      ""		"nls" 	"-m25"	      ; echo ""
				fminer  "-f$f"    "-a"    ""		"nls" 	"-m25"	      ; echo ""
				fminer  "-f$f"    ""      ""		"nop" 	"-m25"	      ; echo ""
				fminer  "-f$f"    "-a"    ""		"nop" 	"-m25"	      ; echo ""

			else
				echo "f: '$f'"
			fi
		fi

	done

}


# Globals
linkdest=""
promille_arr=""
dry_run=true

if [ $# -gt 0 ]; then
	linkdest=$1
	if [ ! -d $linkdest ]; then
		echo "Linkdest not found!"
		echo "Continuing... "
		sleep 3
	fi
	if [ $# -ge 2 ] && [ $2 = "GO" ]; then
		dry_run=false
	fi
  if [ $# -ge 2 ]; then
    promille_arr=$3
    if [ "$promille_arr" = "" ]; then
      echo "Need at least one minimum frequency."
      exit 1
    fi
  fi
else
	echo "$0 [<dir-to-link-to>] [\"GO\"] \"Promille-Array\""
	echo "dir-to-link-to: Directory containing data from previous runs (pass \"\" to omit)"
	echo "Set "GO" to actually execute the task, else set to \"\" for dry-run"
	echo "Set P-A to e.g. "6 8 10 15 20 30 40 50 60 70 80 90 100" to determine minfreq."
	echo ""
	echo "Environment variable: LOODATA must contain a dareqtaset id" 
	echo "  Currently supported: OFS, CPDB"
	exit
fi

source $FLOAT

# CREATE DESTDIR
mkdir "$DESTDIR"

if [ ! -z $linkdest ]; then
	# find $linkdest -type f -size 0 -exec rm {} \; # remove stale files to avoid linking to empty files
	case $linkdest in
		/*) absolute=true ;;
		*) absolute=false ;;
	esac


	if ! $absolute; then
		echo "<dir-to-link-to> must be an absolute path."
		exit 1
	fi

	ln -s $linkdest/* "$DESTDIR/"
fi

if [ -z "$LOODATA" ]; then
	echo "LOODATA not set."
	exit 1
fi

# We can start

# remember my pid
echo $$ >> "$PIDFILE"

if [ "$LOODATA" = "OFS" ]; then
	for d in "$YO" "$YO_NOB"; do
		if $dry_run; then
			bash -c "fminer_loop"
		else
			nohup bash -c "fminer_loop" >> "$OUTFILE" 2>&1 &
		fi
	done
	for d in "$NCTRER" "$NCTRER_NOB"; do
		if $dry_run; then
			bash -c "fminer_loop"
		else
			nohup bash -c "fminer_loop" >> "$OUTFILE" 2>&1 &
		fi
	done
	for d in "$BBB" "$BBB_NOB"; do
		if $dry_run; then
			bash -c "fminer_loop"
		else
			nohup bash -c "fminer_loop" >> "$OUTFILE" 2>&1 &
		fi
	done
fi


if [ "$LOODATA" = "CPDB" ]; then
	for d in "$MCC" "$MCC_NOB"; do
		if $dry_run; then
			bash -c "fminer_loop"
		else
			nohup bash -c "fminer_loop" >> "$OUTFILE" 2>&1 &
		fi
	done
	for d in "$RAT" "$RAT_NOB"; do
		if $dry_run; then
			bash -c "fminer_loop"
		else
			nohup bash -c "fminer_loop" >> "$OUTFILE" 2>&1 &
		fi
	done
	for d in "$MOC" "$MOC_NOB"; do
		if $dry_run; then
			bash -c "fminer_loop"
		else
			nohup bash -c "fminer_loop" >> "$OUTFILE" 2>&1 &
		fi
	done
	for d in "$SALM" "$SALM_NOB"; do
		if $dry_run; then
			bash -c "fminer_loop"
		else
			nohup bash -c "fminer_loop" >> "$OUTFILE" 2>&1 &
		fi
	done
fi


if $dry_run; then
	rm -rf "$DESTDIR"
fi
