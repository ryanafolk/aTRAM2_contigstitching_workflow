#!/bin/bash
myaTRAMfile='best'; # Name pattern of the contig output files
summaryfile='NAMEOFSUMMARYFILE';  
mypath='ABSOLUTE_PATHTOCONTIG_OUTPUTS'; # leave off last "/" of path
pathtoreference='ABSOLUTE_PATHTOREFERENCES'; # leave off last "/" of path
myoverlap='10'; # Leave this as is

array=(lib1 lib2 lib3) # Substitute your library names

#step 1
echo "step 1, running editbestfiles";
editbestfiles.pl;
echo "done with step 1";

#step 2
echo "step 2, running exonerate the first time";
for myref in $pathtoreference\/*.fasta;
do
for lib in ${array[@]};
do
mygene=`expr match "$myref" '.*\(Locus[0-9]*\)'`;
exonerate --model protein2genome $myref $mypath/$lib\_$mygene.$myaTRAMfile.ed.fasta --showvulgar no --showalignment no --ryo "$mygene,$lib,%ql,%qal,%qab,%qae,abyss,%ti\n" >> $mygene.results.out;
done;
fix_csv.pl $mygene.results.out $mygene.results.csv;
LC_ALL=C sort -t, -k 1,1d -k 6,6d -k 4,4n $mygene.results.csv > $mygene.results.sorted.csv;
done;
echo "done with step 2";

#step 2 and three-quarters
# THIS IS THE NEW PART
echo "step 2 and three-quarters, removing paralogous overlaps before stitching";
./paralog_stitch.py
echo "done with step 2 and three-quarters";

#step 3
echo "step 3, running first get contigs";
getcontigs.first.pl;
echo "done with step 3";

##step 4
echo "step 4, stitching";
stitch.aTRAM.contigs.pl  $myoverlap $myaTRAMfile $mypath;
echo "done with step 4";

#step 5
echo "step 5, getting summary data";
summarystats.first.pl > $summaryfile.txt;
echo "done with step 5";

#step 6
echo "step 6, running exonerate for second time";
for secref in $pathtoreference\/*.fasta; 
do
secgene=`expr match "$secref" '.*\(Locus[0-9]*\)'`;
exonerate --model protein2genome $secref $secgene.aTRAM.Exonerate.Round1.OVERLAP.10.fasta  --showvulgar no --showalignment no --ryo "$secgene,%ql,%qal,%qab,%qae,abyss,%ti\n" >> $secgene.exonerate2.out;
fix_csv.pl $secgene.exonerate2.out $secgene.exonerate2.csv; 
LC_ALL=C sort -t, -k 1,1d -k 6,6d -k 4,4n $secgene.exonerate2.csv > $secgene.exonerate2.csv.sorted;
done;

for thiref in $pathtoreference\/*.fasta;
do
thigene=`expr match "$thiref" '.*\(Locus[0-9]*\)'`;
exonerate --model protein2genome $thiref $thigene.aTRAM.Exonerate.Round1.OVERLAP.10.fasta  --showvulgar no --showalignment no --verbose 0 --ryo ">$thigene,abyss,%ti,%qab,%qae\n%tcs\n" >> $thigene.exonerate2.fasta;
done;

editcontigs.pl;
echo "done with step 6";

#step 7
echo "step 7, running second get contigs";
getcontigs.second.pl;
echo "done with step 7";

#step 8
echo "step 8, stitching exonerate contigs";
stitch.Exonerate.contigs.pl;
echo "done with step 8";

##step 9
echo "step 9, generating summary data for the final time";
summarystats.second.pl >> $summaryfile.txt;
echo "done with step 9";
