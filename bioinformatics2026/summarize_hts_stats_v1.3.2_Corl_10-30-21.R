## R

#https://s4hts.github.io/HTStream/
#Parsing JSON log file in R
#The JSON log files produced by HTStream can be parsed easily from within R using the jsonlite package. See the link above for some details.

library(jsonlite)

data.directory <- "Test_reads_from_Pisgah_population_cleaned/HTS_stats_log_files/"

#Gets names of all files in a directory
files <- list.files(path= data.directory);
files

#Initialize vectors to hold the data
filename <- vector(length = length(files), mode="character");
fragments_in <- vector(length = length(files), mode="numeric");
fragments_out <- vector(length = length(files), mode="numeric");
bp_in <- vector(length = length(files), mode="numeric");
bp_out <- vector(length = length(files), mode="numeric");
duplicates <- vector(length = length(files), mode="numeric");
PE_in <- vector(length = length(files), mode="numeric");
PE_out <- vector(length = length(files), mode="numeric");
PE_read1_in_bp <- vector(length = length(files), mode="numeric");
PE_read1_out_bp <- vector(length = length(files), mode="numeric");
PE_read1_Q30_bp_in <- vector(length = length(files), mode="numeric");
PE_read1_Q30_bp_out <- vector(length = length(files), mode="numeric");

for (i in 1:length(files)){
	filename <- files[i]
	
	results = fromJSON(paste(data.directory,files[i], sep=''))
	names(results)

	#Save the fragment stats
	fragment <- results$Fragment
	#names(fragment)
	
	#Figure out how many stats were calculated. This will give the values at the end of the pipeline
	last_stat <- length(fragment$out)

	fragments_in[i] <- fragment$"in"[1]
	fragments_out[i] <- fragment$out[last_stat]
	bp_in[i] <- fragment$basepairs_in[1]
	bp_out[i] <- fragment$basepairs_out[last_stat]
	duplicates[i] <- fragment$duplicate[3]

	#Save the paired end stats
	PE <- results$Paired_end
	#See the part of the PE stats 
	#names(PE)
	#See the structure of how the stats are set up.
	#str(PE)

	#Need the quotes otherwise R thinks it is the R function "in"
	PE_in[i] <- results$Paired_end$"in"[1]
	PE_out[i] <- results$Paired_end$out[last_stat]
	PE_read1_in_bp[i] <- results$Paired_end$Read1$basepairs_in[1]
	PE_read1_out_bp[i] <- results$Paired_end$Read1$basepairs_out[last_stat]
	PE_read1_Q30_bp_in[i] <- results$Paired_end$Read1$total_Q30_basepairs[1]
	PE_read1_Q30_bp_out[i] <- results$Paired_end$Read1$total_Q30_basepairs[last_stat]
}

#Read in the simple names
sample_name <- read.table("Pisgah_names.txt")
names(sample_name) <- "sample_name"

#Calculate some summary statistics
final_percent_fragments <- fragments_out/fragments_in
final_percent_bp <- bp_out/bp_in

#Adding data.frame keeps the columns from all being turned into character data.
all.data <- data.frame(cbind(sample_name,filename,fragments_in,fragments_out,final_percent_fragments,bp_in,bp_out,final_percent_bp,duplicates,PE_in,PE_out,PE_read1_in_bp,PE_read1_out_bp,PE_read1_Q30_bp_in,PE_read1_Q30_bp_out))
all.data

write.table(all.data, file="Pisgah_hts_stats.csv",sep=",")

#------------------------------------------
#Analyze the results

data <- data.frame(read.csv("Pisgah_hts_stats.csv", header =TRUE))
#You can read in metadata about the samples to analyze it together with the read stats, such as information from the lab preparation of the samples
#metadata <- read.table("filename", header = TRUE)

library(ggplot2)
library(gridExtra)

fragments_out_plot <- ggplot(data, aes(x=sample_name, y=fragments_out)) + geom_point()+ theme(axis.text.x = element_text(hjust = 1,size = 10))+ labs(x = "Sample Name",y= "N Fragments Out")

percent_fragments_out_plot <- ggplot(data, aes(x=sample_name, y=final_percent_fragments)) + geom_point()+ theme(axis.text.x = element_text(hjust = 1,size = 10))+ labs(x = "Sample Name",y= "Percent Fragments Out")

bp_out_plot <- ggplot(data, aes(x=sample_name, y=bp_out)) + geom_point()+ theme(axis.text.x = element_text(hjust = 1,size = 10))+ labs(x = "Sample Name",y= "BP Out")

percent_bp_out_plot <- ggplot(data, aes(x=sample_name, y=final_percent_bp)) + geom_point()+ theme(axis.text.x = element_text(hjust = 1,size = 10))+ labs(x = "Sample Name",y= "Percent BP Out")

grid.arrange(fragments_out_plot, percent_fragments_out_plot,bp_out_plot, percent_bp_out_plot)

ggplot(data, aes(x=fragments_out, y=bp_out)) + geom_point()+ theme(axis.text.x = element_text(hjust = 1,size = 10))+geom_smooth(method="lm") +labs(x = "Fragments Out",y= "BP Out")
