#TODO list
#Meter comprobaciones de argumentos y errores
#Poner los echos más bonitos
#Poner todos los mkdir previos por si acaso



#Download all the files specified in data/filenames
echo "Downloading files"
mkdir -p data
for url in $(cat data/urls) 
do
    bash scripts/download.sh $url data
done
#Uncompress all downloaded files

echo "Uncompressing files"
gunzip -k data/*.fastq.gz
mkdir -p data/uncompressed
mv data/*.fastq data/uncompressed

# Download the contaminants fasta file, uncompress it, and 
# filter to remove all small nuclear RNAs
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

echo "Removing adapters from samples" 
for  sampleid in $(ls out/merged/*.fastq.gz | cut -d "." -f1 | cut -d"/" -f3)
do cutadapt \
	-m 18 \
	-a TGGAATTCTCGGGTGCCAAGG \
	--discard-untrimmed \
	-o out/trimmed/${sampleid}.trimmed.fastq.gz out/merged/${sampleid}.fastq.gz > log/cutadapt/${sampleid}.log
done

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

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in

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









