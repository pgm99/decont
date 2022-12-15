# This script should merge all files from a given sample
sampledir=$1
outdir=$2
sampleid=$3
cat $1/$3* > $2/$3.fastq.gz
