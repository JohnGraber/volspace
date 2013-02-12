

# The following assumptions are made in the script below:
#	- the output from the Cache report is pre-sorted by the Database field
#	- the available space field always has units of GB
#	- the lines we care about in the report all have 6 or 7 fields in them (see below)
#	- the first mountpoint in the report is always prd01


BEGIN {

	print "\n\tEPIC VOLUME SPACE REPORT\n"

	current_mountpoint = "prd01"

	threshold = 80

	printf("%-10s%10s%12s%10s\n", "Volume", "Size", "Allocated", "Pct Used")

}


{ # for each line in the text file, do the following

	# Using NF (number of fields) to grab only the lines
	# of the report with enough fields (6+) to be the lines were
	# are looking for.  Also ignore the header row which begins
	# with 'Database'
	if ( NF >= 6 && $1 !~ /Database/ )	{


		# Using the built-in function split() to split apart the
		# file path into a more usable array.
		dirs = split($1,mount,"/")
		mountpoint = mount[3]
		database = mount[4]


		# per Carla, we will ignore the database 'cachesys' and
		# its unlimited max sizes.  Grab only the mountpoints with
		# the format prd##
		if ( database !~ /cachesys/ ) {


			# get the max size field, chop off the units, and divide
			# by 1000 if the units were MB
			match($2, /[GM]B/)
			maxsize = substr($2,1,RSTART-1)
			if ( substr($2,RSTART,1) ~ /M/ ) {
				maxsize = maxsize/1000
				# / this comment does nothing but fix my syntax highlighting by matching the previous slash
			}
			

			# to deal with that damn "<-" that appears in the report,
			# which is recognized as a separate field when using spaces
			# as a field separator...
			if ( NF == 6 ) {
				match($6, /GB/)
				volspace = substr($6,1,RSTART-1)
			}
			else if ( NF == 7 ){
				match($7, /GB/)
				volspace = substr($7,1,RSTART-1)
			}
			# making the assumption that all mountpoints are in GB,
			# so no conversion needed for volspace units above


			# if this is the first line of a new mountpoint, print
			# a summary of the previous mountpoint
			if ( mountpoint != current_mountpoint ) {
				
				vol_size = current_volspace + allocated
				percent_full = allocated / vol_size * 100
				# / this comment does nothing but fix my syntax highlighting by matching the previous slash


				printf("%-10s%10.2f%12.2f%10.2f\n", current_mountpoint, vol_size, allocated, percent_full)

				if ( percent_full > threshold ) {
					print "\n\t*** VOLUME SIZE WARNING ***"
				}

				# reinitialize
				allocated = 0
			}

			# update variables for next loop
			current_mountpoint = mountpoint
			current_volspace = volspace
			allocated += maxsize

		}

	}

}

END {

	# printing results one last time for the final mountpoint once the loop
	# above has completed processing all of the lines in the text file.
	# this is a copy/paste of the summary code within the loop

	vol_size = current_volspace + allocated
	percent_full = allocated / vol_size * 100
	# / this comment does nothing but fix my syntax highlighting by matching the previous slash


	printf("%-10s%10.2f%12.2f%10.2f\n\n\n", current_mountpoint, vol_size, allocated, percent_full)


}

# NF == 6 /^\/epic\/prd[0-9][0-9]/ { print $1 $2 $6 }
