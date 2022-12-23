i


#Download all the files specified in data/filenames, and uncompress if "yes" is added as third argument

echo "Downloading files"
mkdir -p data
for url in $(cat data/urls) 
do
    bash scripts/download.sh $url data yes
done

# Download the contaminants fasta file, uncompress it, and 
# filter to remove all small nuclear RNAs

mkdir -p res
bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res
gunzip -k res/contaminants.fasta.gz
sed /'small nuclear'/d res/contaminants.fasta > res/clean_contaminants.fasta

# Index the contaminants file

echo "Creating contaminants STAR index"
bash scripts/index.sh res/clean_contaminants.fasta res/contaminants_index

# Merge the samples into a single file

echo "Merging uncompressed samples files"
mkdir -p out/merged
for sid in $(ls data/*.fastq.gz | cut -d"-" -f1 | sed 's:data/::')

do
    bash scripts/merge_fastqs.sh data out/merged $sid
done

mkdir -p out/trimmed
mkdir -p log/cutadapt
#Cutadapt the samples, removing adapters used

echo "Removing adapters from samples" 
for  sampleid in $(ls out/merged/*.fastq.gz | cut -d "." -f1 | cut -d"/" -f3)
do cutadapt \
	-m 18 \
	-a TGGAATTCTCGGGTGCCAAGG \
	--discard-untrimmed \
	-o out/trimmed/${sampleid}.trimmed.fastq.gz out/merged/${sampleid}.fastq.gz > log/cutadapt/${sampleid}.log
done

echo "Started mapping"

mkdir -p out/star
for fname in out/trimmed/*.fastq.gz
do

    sid=$(echo $fname | sed 's:out/trimmed/::' | cut -d "." -f1)
    mkdir -p out/star/$sid
    STAR \
	    --runThreadN 4 \
	    --genomeDir res/contaminants_index \
	    --outReadsUnmapped Fastx \
	    --readFilesIn $fname \
	    --readFilesCommand gunzip -c \
	    --outFileNamePrefix out/star/$sid
done 

echo"Mapping succesfully"

echo "---Creating a log file containing information from cutadapt and STAR logs---"

for sid in $(ls data/*.fastq.gz | cut -d "-" -f1 | sed 's:data/::' | uniq)
do
	echo "--------Sample: " $sid "--------" >> log/pipeline.log
	
	echo "Cutadapt: " >> log/pipeline.log
	echo $(cat log/cutadapt/$sid.log | grep -e "Reads with adapters") >> log/pipeline.log
	echo $(cat log/cutadapt/$sid.log | grep -e "Total basepairs") >> log/pipeline.log
	echo -e "\n" >> log/pipeline.log

	echo "STAR: " >> log/pipeline.log
	echo $(cat out/star/$sid"Log.final.out" | grep -e "Uniquely mapped reads %") >> log/pipeline.log
	echo $(cat out/star/$sid"Log.final.out" | grep -e "% of reads mapped to multiple loci") >> log/pipeline.log
	echo $(cat out/star/$sid"Log.final.out" | grep -e "% of reads mapped to too many loci") >> log/pipeline.log
	echo -e "\n" >>log/pipeline.log
done

echo "----log file created----"








