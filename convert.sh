#!/bin/bash

# Check if the converterfile exists
if [ ! -f $PWD/video_formats.json ]
then
	exit 1;
fi

# Loop through our convertfile and convert the video
videoformats=$(<video_formats.json)

# TODO: options to pass (via options or Environments Variables)
# * A different video_formats_location
# * A different folder
# * Everything which is a Video Format
# * ffmpeg path

# Remove Spaces in filename (because bash doesn't like them and would throw an error)
rename 's/ /_/g' *

# Run every 5 seconds
while true; do
	# loop through all files
	for file in $PWD/*; do
		# Check if the current file is a video
		if [ ${file: -4} == ".mp4" ]
		then
			
			# If it is a videofile, if no "locker" already exists, create one and start converting
			if [ ! -f $file.lock ]
			then

				# Tell the User what we're doing
				echo "================"
				echo "Found file: $file"

				# Create Lock file
				touch $file.lock

				# Create the output folder
				mkdir $file.out
				
				# Loop through all videoformats and convert them
				for row in $(echo "${videoformats}" | jq -r '.[] | @base64'); do  
					_jq() {
						echo ${row} | base64 --decode | jq -r ${1}
					}
					
					echo "Converting to $(_jq '.name'), Resolution: $(_jq '.resolution'), Bitrate: $(_jq '.video_bitrate'), Framerate: $(_jq '.framerate')"

					# Make Framerate optional, don't use Framerate if it is not set
					framerate=""
					if [ "$(_jq '.framerate')" != "null" ]
					then
						framerate=" -r $(_jq '.framerate')"
					fi

					# Convert
					ffmpeg -i $file -b:v $(_jq '.video_bitrate') $framerate -c:v $(_jq '.video_codec') -vf scale=$(_jq '.resolution') -c:a $(_jq '.audio_codec') -b:a $(_jq '.audio_bitrate') $file.out/$(basename "$file" .mp4)_$(_jq '.name').$(_jq '.file_ending') &
				done

				# Wait until all formats are created
				wait

				# Cleanup: Remove the lockfile, move the original to the converted folder.
				mv $file $file.out/$(basename "$file" .mp4)_orig.mp4
				rm $file.lock
				touch $file.out/$(basename "$file" .mp4).done

				echo "Finished Converting $file"

				echo "================"
			fi
		fi
	done

	sleep 5s
done
