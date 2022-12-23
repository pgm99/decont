if [ "$3" == "yes" ]
then
        wget -nc -P $2 $1
	echo "Uncompressing files"
	gunzip -k data/*fastq.gz
	mkdir -p data/uncompressed
	mv data/*.fastq data/uncompressed
else
        wget -nc -P $2 $1
fi



