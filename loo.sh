#!/bin/bash

# export everything to newly created subshells
set -a 

export FMINER_LAZAR="1"
export FMINER_SMARTS="1"

source $HOME/.bash_ob
source $HOME/.bash_r
source $HOME/.bash_ruby
source $HOME/.bash_gems

NICE="nice -n 19"
RUBY="`which ruby`"
FMINER="$NICE $HOME/fminer2/fminer/fminer $HOME/fminer2/liblast/liblast.so"
LAZAR="$NICE $HOME/lazar-core/lazar"
L2S="$NICE $RUBY $HOME/lazar-core/loo2summary.rb"
COVERAGE="$NICE $RUBY $HOME/xvalgenerator/coverage.rb"
LU="$NICE $RUBY $HOME/last-utils/last-utils.rb"
FLOAT="$HOME/bin/float.sh"

MCC="$HOME/cpdbdata/multi_cell_call/multi_cell_call_alt.smi $HOME/cpdbdata/multi_cell_call/multi_cell_call_alt.class"
SALM="$HOME/cpdbdata/salmonella_mutagenicity/salmonella_mutagenicity_alt.smi $HOME/cpdbdata/salmonella_mutagenicity/salmonella_mutagenicity_alt.class"
RAT="$HOME/cpdbdata/rat_carcinogenicity/rat_carcinogenicity_alt.smi $HOME/cpdbdata/rat_carcinogenicity/rat_carcinogenicity_alt.class"
MOC="$HOME/cpdbdata/mouse_carcinogenicity/mouse_carcinogenicity_alt.smi $HOME/cpdbdata/mouse_carcinogenicity/mouse_carcinogenicity_alt.class"
MCC_NOB="$HOME/cpdbdata/multi_cell_call/multi_cell_call_alt.nob.smi $HOME/cpdbdata/multi_cell_call/multi_cell_call_alt.class"
SALM_NOB="$HOME/cpdbdata/salmonella_mutagenicity/salmonella_mutagenicity_alt.nob.smi $HOME/cpdbdata/salmonella_mutagenicity/salmonella_mutagenicity_alt.class"
RAT_NOB="$HOME/cpdbdata/rat_carcinogenicity/rat_carcinogenicity_alt.nob.smi $HOME/cpdbdata/rat_carcinogenicity/rat_carcinogenicity_alt.class"
MOC_NOB="$HOME/cpdbdata/mouse_carcinogenicity/mouse_carcinogenicity_alt.nob.smi $HOME/cpdbdata/mouse_carcinogenicity/mouse_carcinogenicity_alt.class"

YO="$HOME/ofsdata/yoshida.smi $HOME/ofsdata/yoshida.class"
NCTRER="$HOME/ofsdata/nctrer.smi $HOME/ofsdata/nctrer.class"
BBB="$HOME/ofsdata/bloodbarr.alt.smi $HOME/ofsdata/bloodbarr.alt.class"
YO_NOB="$HOME/ofsdata/yoshida.nob.smi $HOME/ofsdata/yoshida.class"
NCTRER_NOB="$HOME/ofsdata/nctrer.nob.smi $HOME/ofsdata/nctrer.class"
BBB_NOB="$HOME/ofsdata/bloodbarr.alt.nob.smi $HOME/ofsdata/bloodbarr.alt.class"


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


	if [ -z $nob ] || [ -n $a ]; then
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
			local frags2="$name$f$hops$a$nob$db-$var.frag2"
			local frags3="$name$f$hops$a$nob$db-$var.frag3"
			lu "$frags" "$frags2" "$frags3" "$var" "$a"

			local loo="$(echo $frags3 | sed 's/\.frag3/\.loo/g')"
			local summ="$(echo $frags3 | sed 's/\.frag3/\.summary/g')"
			lazar $loo $frags3 $summ
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
	local smi=`echo "$d" | sed 's/\ .*//g'`

	local nna="false"
	local wcb="false"

	# Don't annotate nodes, but wildcard all bonds
	if [ "$a" != "" ]; then
		nna="nna"
		awc="awc"

	# Don't annotate nodes, but also do not wildcard bonds
	else
		nna="nna"
		awc="nawc"
	fi

	local lu_cmd="$LU 1 $var a w < $DESTDIR/$frags > $DESTDIR/$frags2"
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
	#	for p in 5 6 7 8 10 15 20 30 40 50 60 70 80 90 100; do
	for p in 20 30 40 50 60 70 80 90 100; do
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


linkdest=""
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
else
	echo "$0 [<dir-to-link-to>] [\"GO\"]"
	echo "dir-to-link-to: Directory containing data from previous runs (pass \"\" to omit)"
	echo "Set 'GO' to actually execute the task"
	echo ""
	echo "Environment variable: LOODATA must contain a dataset id" 
	echo "  Currently supported: OFS, CPDB"
	exit
fi

source $FLOAT
DATE="`date +%y%m%d-%H%M%S`"
LASTDIR="$HOME/last_variant_testing"
DESTDIR="$LASTDIR/$DATE"
OUTFILE="$LASTDIR/loo-output-$LOODATA-m25-$DATE.txt"
PIDFILE="$LASTDIR/loo-output-$LOODATA-m25-$DATE.pid"

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
			echo $! >> "$PIDFILE"
		fi
	done
	wait
	for d in "$NCTRER" "$NCTRER_NOB"; do
		if $dry_run; then
			bash -c "fminer_loop"
		else
			nohup bash -c "fminer_loop" >> "$OUTFILE" 2>&1 &
			echo $! >> "$PIDFILE"
		fi
	done
	wait
	for d in "$BBB" "$BBB_NOB"; do
		if $dry_run; then
			bash -c "fminer_loop"
		else
			nohup bash -c "fminer_loop" >> "$OUTFILE" 2>&1 &
			echo $! >> "$PIDFILE"
		fi
	done
fi


if [ "$LOODATA" = "CPDB" ]; then
	for d in "$MCC" "$MCC_NOB"; do
		if $dry_run; then
			bash -c "fminer_loop"
		else
			nohup bash -c "fminer_loop" >> "$OUTFILE" 2>&1 &
			echo $! >> "$PIDFILE"
		fi
	done
	for d in "$RAT" "$RAT_NOB"; do
		if $dry_run; then
			bash -c "fminer_loop"
		else
			nohup bash -c "fminer_loop" >> "$OUTFILE" 2>&1 &
			echo $! >> "$PIDFILE"
		fi
	done
	for d in "$MOC" "$MOC_NOB"; do
		if $dry_run; then
			bash -c "fminer_loop"
		else
			nohup bash -c "fminer_loop" >> "$OUTFILE" 2>&1 &
			echo $! >> "$PIDFILE"
		fi
	done
	for d in "$SALM" "$SALM_NOB"; do
		if $dry_run; then
			bash -c "fminer_loop"
		else
			nohup bash -c "fminer_loop" >> "$OUTFILE" 2>&1 &
			echo $! >> "$PIDFILE"
		fi
	done
fi


if $dry_run; then
	rm -rf "$DESTDIR"
fi
