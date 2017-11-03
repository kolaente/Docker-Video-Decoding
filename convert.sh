#!/bin/bash

########
# Init Variables
# Available Environment Variables:

# VIDEO_FORMATS_LOCATION: Pass a location to a different json file holding video convert configurations
# VIDEO_LOCATION: Pass a location to a different folder which holds the videos
# VIDEO_FORMATS: Pass all video formats which should trigger the conversion, seperated by ":". Example: .mp4:.wmv
# VIDEO_FFMPEG_PATH: Path to ffmpeg executable
########

########
# Environment variables as a base
########

# Video formats location
if [ -n $VIDEO_FORMATS_LOCATION ]
then
	video_formats_location=$VIDEO_FORMATS_LOCATION
fi

# Video location
if [ -n $VIDEO_LOCATION ]
then
	video_location=$VIDEO_LOCATION
fi

# All video formats
if [ -n $VIDEO_FORMATS ]
then
	video_formats_string=$VIDEO_FORMATS
fi

# ffmpeg executable
if [ -n $VIDEO_FFMPEG_PATH ]
then
	video_ffmpeg_path=$VIDEO_FFMPEG_PATH
fi

########
# Passed Options, any passed option will overwrite a previously set environment variable
########

while getopts ":c:p:v:p:h" opt; do
  case $opt in
    c)
      video_formats_location=$OPTARG
      ;;
    p)
      video_location=$OPTARG
      ;;
    v)
      video_formats_string=$OPTARG
      ;;
    f)
      video_ffmpeg_path=$OPTARG
      ;;
    h)
      echo "AVAILABLE OPTIONS: 
 
-c: Video Formats Location. Pass a path with a JSON config file for conversion. Defaults to 'video_formats.json' in current folder. 
-p: Video Location. Pass a location to a different folder which holds the videos. Defaults to currents folder. 
-v: Video Formats. Pass all video formats which should trigger the conversion, seperated by ':'. Example: .mp4:.wmv 
-f: Path to ffmpeg executable. Defaults to 'ffmpeg'
-h: Print this help message.

ENVIRONMENT VARIABLES: 
All settings can also be done via environment variables. However, a passed option will overwrite a previously set environment variable. 
 
VIDEO_FORMATS_LOCATION: Pass a location to a different json file holding video convert configurations 
VIDEO_LOCATION: Pass a location to a different folder which holds the videos 
VIDEO_FORMATS: Pass all video formats which should trigger the conversion, seperated by ':. Example: .mp4:.wmv 
VIDEO_FFMPEG_PATH: Path to ffmpeg executable 
 
Copyright 2017 K. Langenberg 
Licensed under GNU GPLv3"
	  exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG. Use -h to print all available options." >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument. Use -h to print all available options." >&2
      exit 1
      ;;
  esac
done

########
# Defaults
########

# Video Formats Location
if [ -z $video_formats_location ]
then 
	video_formats_location=$PWD/video_formats.json
fi

# Video Location
if [ -z $video_location ]
then 
	video_location=$PWD
fi

# Video Formats
if [ -z $video_formats_string ]
then 
	video_formats_string='.mp4'
fi

# Default ffmpeg path
if [ -z $video_ffmpeg_path ]
then
	video_ffmpeg_path=ffmpeg
fi

########
# Checks
########
# Check if the converterfile exists
if [ ! -f $video_formats_location ]
then
	echo "Video Formats .json file ($video_formats_location) does not exist!"
	exit 1;
fi

# Check if the video folder exists
if [ ! -d $video_location ]
then
	echo "Video location folder ($video_location) does not exist!"
	exit 1;
fi

# Remove end slash in video location
video_location=${video_location%/}

# Loop through our convertfile
video_formats_file=$(<$video_formats_location)

########
# Run every 5 seconds
########

while true; do
	# Remove Spaces in filename (because bash doesn't like them and would throw an error)
	rename 's/ /_/g' *
	
	# loop through all files
	for file in $video_location/*; do
		# Check if the current file is a video
		file_format=${file: -4}
		if [ "${video_formats_string/$file_format}" != "$video_formats_string" ]
		then

			# If it is a videofile, if no "locker" already exists, create one and start converting
			if [ ! -f $file.lock ]
			then

				# Tell the User what we're doing
				echo "================"
				echo "Found file: $file"

				# Create Lock file
				touch $file.lock

				# Check if the file is a video file
				# TODO

				# Create the output folder
				mkdir $file.out

				# Get the video width and height
				# Hack to get the height even if the audio and video stream are in reverse order
				codec_type=$(ffprobe -v quiet -show_streams -print_format json "$file" | jq --raw-output '.streams [0] .codec_type')
				if [ "$codec_type" = "video" ]
				then
					video_height=$(ffprobe -v quiet -show_streams -print_format json "$file" | jq '.streams [0] .height')
				else
					video_height=$(ffprobe -v quiet -show_streams -print_format json "$file" | jq '.streams [1] .height')
				fi

				# Loop through all videoformats and convert them
				for row in $(echo "${video_formats_file}" | jq -r '.[] | @base64'); do  
					_jq() {
						echo ${row} | base64 --decode | jq -r ${1}
					}

					# Check if the video is larger or as large as the format we want to convert it to
					IFS=':' read -r -a video_resolutions <<< "$(_jq '.resolution')"

					# TODO don't ignore aspect ratio, maybe even only input a height in conversion json file, calculate the with based on aspect ration obtained from ffprobe

					if [ "${video_resolutions[1]}" -le "$video_height" ]
					then
						echo "Converting to $(_jq '.name'), Resolution: $(_jq '.resolution'), Bitrate: $(_jq '.video_bitrate'), Framerate: $(_jq '.framerate')"

						# Make Framerate optional, don't modify the framerate if it is not set
						framerate=""
						if [ "$(_jq '.framerate')" != "null" ]
						then
							framerate=" -r $(_jq '.framerate')"
						fi

						# Convert
						$video_ffmpeg_path -i $file -b:v $(_jq '.video_bitrate') $framerate -c:v $(_jq '.video_codec') -vf scale=$(_jq '.resolution') -c:a $(_jq '.audio_codec') -b:a $(_jq '.audio_bitrate') $file.out/$(basename "$file" "$file_format")_$(_jq '.name').$(_jq '.file_ending') &
					fi
				done

				# Wait until all formats are created
				wait

				# Cleanup: Remove the lockfile, move the original to the converted folder.
				mv $file $file.out/$(basename "$file" "$file_format")_orig"$file_format"
				rm $file.lock
				touch $file.out/$(basename "$file" "$file_format").done

				echo "Finished Converting $file"

				echo "================"
			fi
		fi
	done

	# Every 5 seconds...
	sleep 5s
done
