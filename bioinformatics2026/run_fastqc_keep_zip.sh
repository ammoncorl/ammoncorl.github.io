#!/bin/bash

## assumes fastqc is available on the Pathway
##Usage:  sh run_fastqc.sh -i data_directory -o name_of_output_directory

echo "Usage:  sh run_fastqc.sh -i data_directory -o name_of_output_directory"


#https://www.lifewire.com/pass-arguments-to-bash-script-2200571
while getopts i:o: option
do
case "${option}"
in
i) inpath=${OPTARG};;
o) outpath=${OPTARG};;

esac
done

start=`date +%s`

mkdir ${inpath}/${outpath}


#Assumes that files have the ending fastq.gz
for file in ${inpath}/*.fastq.gz
do
  	#The sample name will appear in the terminal when it is being processed
  	echo "SAMPLE: ${file}"
  
	#This is the command that will be used to run fastqc
	#I needed to at -t 2 to have it run on Tilden.  Otherwise it ran out of memory
	call="fastqc ${file} -o ${inpath}/${outpath} -t 4"
	#output the call to the terminal
	echo $call
	#Need this eval command to have the call run.
	eval $call
done 


end=`date +%s`
runtime=$((end-start))
echo "The runtime was: "$runtime 
echo "seconds."