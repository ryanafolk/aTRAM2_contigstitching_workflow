#!/usr/bin/env python3
# This script replaces the behavior of the stitching script for post-processing aTRAM best files.
# We assume the behavior of the other script: a file sorted by taxon and contig beginning coordinate (column 4)
# Instead of favoring length, this script picks among overlapping contigs by BLAST bitscore.
# Relative bitscore ranks are stored as the last number of the contig names.

import glob
import csv 
import re
import sys
import os
import shutil

exportlist = []

for file in glob.iglob('*.results.sorted.csv'): # Iterate over all files matching this pattern
	exportlist = [] # Clear export list for every new file.
	if os.stat(file).st_size == 0:
		continue
	print(file)
	with open(file, 'r') as datafile:
		reader=csv.reader(datafile, delimiter=',', quoting=csv.QUOTE_NONE) 
		previous_line = next(reader) # This and the following line harvest the first pair of intervals
		try:
			current_line = next(reader)
		except: 
			print("Only one item.")
			exportlist.append(previous_line)
			pass
		while(True): # This loop is set up to compare neighboring csv lines
			try: 
				if current_line[0] != previous_line[0]: # Check if we are comparing two libraries; move onto the next taxon and prevent a cross-taxon comparison if yes
					exportlist.append(previous_line) # Save the last contig, which is non-overlapping and optimal at this point
					print("next library")
					previous_line = current_line 
					current_line = next(reader)
					pass
				elif int(current_line[3]) <= int(previous_line[4]): # Check for overlap (if beginning of a contig is before the end of the previous one)
					print("overlap")
					print("{}, {}".format(previous_line[3],previous_line[4]))
					print("{}, {}".format(current_line[3],current_line[4]))
					current_line_rank = re.match('.*?([0-9]+)$', current_line[6]).group(1)
					previous_line_rank = re.match('.*?([0-9]+)$', previous_line[6]).group(1)
					if int(previous_line_rank) > int(current_line_rank): # New contig has a better score
						previous_line = current_line # Take new line
						current_line = next(reader)
						print("chose {} over {}".format(current_line_rank, previous_line_rank))
						pass
					elif int(current_line_rank) > int(previous_line_rank): # New contig has a worse score
						current_line = next(reader)
						print("chose {} over {}".format(previous_line_rank, current_line_rank))
						pass # Keep old line
					elif int(current_line_rank) == int(previous_line_rank): # This should never be true, but in practice can happen with duplicate contigs occasionally
						print("File has incorrect ranks; duplicates?")
						previous_line = current_line # Take new line
						current_line = next(reader)
						pass
				elif int(current_line[3]) > int(previous_line[4]): # New and old contigs do not overlap
					print("{} end and {} beginning are nonoverlapping".format(previous_line[4], current_line[3]))
					exportlist.append(previous_line)
					previous_line = current_line
					current_line = next(reader)
					pass
				else:
					print("Error")
					sys.exit()
			except:
				break
	
	oldfilename = file
	oldfilename += ".old" # Save original files
	shutil.move(file, oldfilename)
	with open(file, 'w+') as writefile:
		writer = csv.writer(writefile, delimiter=',', lineterminator = os.linesep) # Setting line terminator correctly is important.
		for row in exportlist:
			writer.writerows([row]) # Brackets are needed
	