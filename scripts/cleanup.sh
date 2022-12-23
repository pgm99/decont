#Specific cleanup script, do not use for another WD
echo "Starting cleanup for WD..."

cd data
rm *.fastq.gz
cd uncompressed
rm -r *
cd ..
cd ..
cd res
rm -r *
cd ..
cd out
rm -r *
cd ..
cd log
rm -r *
echo "Cleanup completed, please check WD"
