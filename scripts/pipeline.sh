#Download all the files specified in data/filenames
echo "Downloading files"
for url in $(cat data/urls) 
do
    bash scripts/download.sh $url data
done

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
for sid in $(<list_of_sample_ids>) #TODO
do
    bash scripts/merge_fastqs.sh data out/merged $sid
done

# TODO: run cutadapt for all merged files
# cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
#     -o <trimmed_file> <input_file> > <log_file>

# TODO: run STAR for all trimmed files
for fname in out/trimmed/*.fastq.gz
do
    # you will need to obtain the sample ID from the filename
    sid=#TODO
    # mkdir -p out/star/$sid
    # STAR --runThreadN 4 --genomeDir res/contaminants_idx \
    #    --outReadsUnmapped Fastx --readFilesIn <input_file> \
    #    --readFilesCommand gunzip -c --outFileNamePrefix <output_directory>
done 

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in
