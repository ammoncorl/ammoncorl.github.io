#!/bin/bash

## assumes htstream is available on the Pathway

start=`date +%s`
echo $HOSTNAME

##Name of the directory for the raw data
inpath='Your_raw_data_folder_name'
##Name of the directory for the processed data
outpath='Your_cleaned_data_folder_name'
##Name of the file of samples
sample_names='Your_sample_name_file.txt'
##Name of the file of adapter sequences to screen against
adapters='Your_adapter_sequences_file.txt'


##Makes a directory to store the processed data
[[ -d ${outpath} ]] || mkdir ${outpath}

##Makes a separate directory to store the log files
mkdir ${outpath}/HTS_stats_log_files

## Need a file with the sample names.  
## There is an opportunity to parallelize things here.  Could give separate lists of samples and run the script separately for the different sets.

##Loop over all the samples
for sample in `cat ${sample_names}`
do
  #The sample name will appear in the terminal when it is being processed
  echo "SAMPLE: ${sample}"
  
  ##Quick pipeline overview
    ## 1. hts_Stats: get stats on raw reads
    ## 2. hts_SeqScreener: screen out (remove) phiX
    ## 3. hts_SuperDeduper: identify and remove PCR duplicates
    ## 4. hts_Overlapper: identify and remove adapter sequence, merge any reads that significantly overlap
    ## 5. hts_SeqScreener: screen for any remaining adapters
    ## 6. hts_QWindowTrim: remove poor quality sequence
    ## 7. hts_NTrimmer: remove any remaining N characters
    ## 8. hts_LengthFilter: use to remove all reads < 50bp
    ## 9. hts_Stats: get stats on output reads

  

	##In the first routine we use -1 and -2 to specify the original reads.
	##For the log, we specify -L with the same log file name for all routines, and use -A for the second routine onward to append log output, generating a single log file at the end.
	##All other parameters are algorithm specific, can review using –help
	
	##hts_SeqScreener identifies and removes any reads which appear to have originated from a contaminant DNA source. Because bacteriophage Phi-X is common spiked into Illumina runs for QC purposes, sequences originating from Phi-X are removed by default. If other contaminants are suspected their sequence can be supplied as a fasta file <seq>, however the algorithm has been tuned for short contaminant sequences, and may not work well with sequences significantly longer than Phi-X (5Kb).
	##The first call of SeqScreener in the pipeline filters out the default of Phix Sequence. 
	
	##hts_SuperDeduper is a reference-free PCR duplicate remover. It uses a subsequence within each read as a unique key to detect duplicates in future reads. Reads with 'N' character(s) in the key sequence are ignored.  hts_SuperDeduper is not recommended for single-end reads.  WARNING: hts_SuperDeduper will only work correctly on untrimmed reads.filters out duplicated sequences.  
	##Thus, only use this for paired end reads and before adapter trimming.  The -e flag is the "Frequency in which to log duplicates in reads, can be used to create a saturation plot (0 turns off).  If -e = 250000, this thus records how many duplicates are in the first 250000 reads, then the next 250000 reads and so on.  
	
	##The hts_Overlapper application attempts to overlap paired end reads to produce the original transcript, trim adapters, and in some cases, correct sequencing errors.  If the reads overlap it will export a single merged read.  If the reads do not overlap significantly, it will export PE reads.
	##If you want to maintain the PE format, use Adapter Trimmer instead, which exports PE data.  It trims off adapters by first overlapping paired-end reads and trimming off overhangs which by definition are adapter sequence in standard libraries. 
	 	
	##The second call of SeqScreener filters out any remaining adapter sequences.  The HT Stream website says "This tool can also be useful in removing primer dimers and other reads containing sequencing adapters. For example, setting -k 15 -x .01 in combination with a collection of adapters in fasta format, has been found to work well for this purpose."
	
	##hts_QWindowTrim uses a sliding window approach to remove low quality bases (5' or 3') from a read. A window will slide from each end of the read, moving inwards. Once the window reaches an average quality <avg-qual> it will stop trimming.
	##I will use the defaults of a window size of 10 and an average quality threshold of 20.
		
	##The hts_NTrimmer application will identify and return the longest subsequence that no N characters appear in.
  	  	
	##The hts_LengthFilter application filters reads that are too long or too short.
	##-m flag is the minimum length for acceptable output read (min 1, max 10000), default is unset                                       
	
	##The hts_Stats app produce basic statistics about the reads in a dataset.  Including the basepair composition and number of bases Q30.  
	## The -f flag outputs a Fastq file.
	
	
	##Note:  I have it set up to make a folder and save all the log files to that folder.  The UC Davis group has the log files for each sample saved in its own folder.  To save everything in its own folder log the data to "${outpath}/${sample}/${sample}_htsStats.log " rather than to "${outpath}/HTS_stats_log_files/${sample}_htsStats.log"
	
  call="hts_Stats -L ${outpath}/HTS_stats_log_files/${sample}_htsStats.log -N 'initial stats' -1 ${inpath}/${sample}*R1* -2 ${inpath}/${sample}*R2* | \
        hts_SeqScreener -A ${outpath}/HTS_stats_log_files/${sample}_htsStats.log  -N 'screen phix' | \
        hts_SuperDeduper -e 250000 -A ${outpath}/HTS_stats_log_files/${sample}_htsStats.log -N 'remove PCR duplicates' | \
        hts_Overlapper -A ${outpath}/HTS_stats_log_files/${sample}_htsStats.log  -N 'trim adapters and overlap' | \
        hts_SeqScreener -s ${adapters} -k 15 -x .01 -A ${outpath}/HTS_stats_log_files/${sample}_htsStats.log -N 'screen remaining adapters' | \
        hts_QWindowTrim -A ${outpath}/HTS_stats_log_files/${sample}_htsStats.log -N 'quality trim the ends of reads'  | \
        hts_NTrimmer -A ${outpath}/HTS_stats_log_files/${sample}_htsStats.log -N 'remove any remaining N characters'  | \
        hts_LengthFilter -A ${outpath}/HTS_stats_log_files/${sample}_htsStats.log  -N 'remove reads < 20bp' -m 20 | \
        hts_Stats -A ${outpath}/HTS_stats_log_files/${sample}_htsStats.log -N 'final stats'  -f ${outpath}/${sample}"

  echo $call
  eval $call
done

end=`date +%s`
runtime=$((end-start))
echo "The runtime was: "$runtime
