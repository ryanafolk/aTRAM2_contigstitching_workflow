# Change naming format back to aTRAM 1.0
# Main thing is having it end in .best.fasta
# Just in case the fasta name is also modified to the old standard

mkdir atram_2_format
for i in $(find . -name "*.fasta"); do
sed 's/.* iteration=/>/g' ${i} | sed 's/ contig_id/.0_contigid/g' | sed 's/contigid.*length_//g' | sed 's/_cov.* score=/_/g' | sed 's/\.[0-9]*$//g' > ${i}.reduced.fasta
mv ${i} atram_2_format
done

# Must end in best.fasta
find . -name "*fasta.reduced.fasta" -exec rename 's/fasta\.reduced\.fasta/best.fasta/g' {} \;
# No underscore in locus name
find . -name "*best.fasta" -exec rename 's/Locus_/Locus/g' {} \;

find . -name "*best.fasta" -exec rename 's/\.atram2\.filtered_contigs//g' {} \;
find . -name "*best.fasta" -exec rename 's/lib_//g' {} \;
find . -name "*best.fasta" -exec rename 's/\.Locus/_Locus/g' {} \;

# Make sure files look like: P01_WE2_Locus104.best.ed.fasta
