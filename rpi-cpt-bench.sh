#!/usr/bin/env bash


### Raspi CPT (CPU, Power, Temperature) benchmark
#This script is made for raspi 3 Model B (stress all 4 cores, adapt it for other models)

PATH=$PATH:/opt/vc/bin/
DURATION=$1
OUTPUT_FILE=$2

function usage() {
	echo "USAGE: $(basename $0) DURATION OUTPUT_FILE"
	echo "DURATION is the desired duration for the benchmark in seconds"
	echo "OUTPUT_FILE is the path of the file where the benchmark results will be stored"
	echo "Running this script without parameter will show this help message"
}

function err() {
	echo $@ > /dev/stderr
}

function clock_speed() {
	echo $(vcgencmd measure_clock arm | cut -d'=' -f2)
}

function temp() {
	echo $(vcgencmd measure_temp | cut -d'=' -f2 | rev | cut -c3- | rev)
}

function throttle() {
	echo $(vcgencmd get_throttled | cut -d'=' -f2)
}

function measure() {
	clear
	echo $k\;$(clock_speed)\;$(temp)\;$(throttle) >> $OUTPUT_FILE
	tail -n 1 $OUTPUT_FILE
	sleep 1
	k=$((k+1))
}

if [ $# -lt 2 ]; then
       usage

#Unelegant way to test if a variable is an integer
elif [ ! $((1/$DURATION)) ]; then
	err "The specified duration is not an integer."
	err  "Aborting."
	exit 1

elif [ -f $OUTPUT_FILE ]; then
	err "$OUTPUT_FILE already exists."
	err "Aborting."
	exit 2


elif [ ! -x $(/bin/which stress) ]; then
	err "The \"stress\" program is not in your PATH or is not executable."
	err "Aborting." $ERR
	exit 3

else
	echo "#Time elapsed (s);CPU frequency (Hz);CPU temperature (°C);Throtted (Bool)" > $OUTPUT_FILE

	k=0

	stress -c 4 -t $((DURATION+1))s > /dev/null &
	STRESS_PID=$!
	trap "kill $STRESS_PID 2> /dev/null" EXIT

	#FIXME: Inaccurate number of measurement on a long period of time
	while kill -0 $STRESS_PID 2> /dev/null; do
		measure
		done

fi
