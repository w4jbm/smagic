#!/bin/bash

#####
#
# sumagic.sh - Sumo music processing script by Jim McClanahan, W4JBM
#
# Check most streaming platforms or YouTube for music from
# !!!                The Daft Spaniels                 !!!
#
#####
#
# This script accepts a single command line argument 'name' and expects two files to exist:
#   name.wav - the orignal downloaded audio file from suno.com
#   name.jpg - a square album art image (1600x1600 resolution as used by streaming services)
#
# The output six output files are have the raw name of ARTIST - SONG TITLE
#   ARTIST - SONG TITLE_RAW.wav is the input WAV file converted to a sample rate of 44.1kHz.
#   ARTIST - SONG TITLE_MSTR.wav is normalized to -1 dB with full dynamic range.
#   ARTIST - SONG TITLE_COMP.wav has the compressed audio for streaming services.
#   ARTIST - SONG TITLE.mp3 is the MP3 file with tags and album art.
#   ARTIST - SONG TITLE.mp4 has the square album art for social media.
#   ARTIST - SONG TITLE_YT.mp4 has album art streched for YouTube.
#
# There are a number of commands called as part of this script. If these are not installed
# they will need to be installed using the appropriate tool for your flavor of Linux.
#
# NOTE: For image processing, this script uses the command 'convert' which may be called
#       'magick' depending on your specific distribution and/or version.
#
# Installation:
# Copy the script to the directory you want to work in and use 'chmod +x smagic.sh' to
# make it executable. You should be able to run it using './smagic.sh song_title'.
#
# Revision History:
# v1.0 - Oct 2026 - Initial version.
#
# Known Issues:
#   - Limited Error Checking
#
#####


# Check if the number of arguments is equal to 0
if [ $# -eq 0 ]; then
    echo "Error: Please provide the file name for the .wav and .jpg files."
    echo "Usage: $0 [songname]"
    exit 1
fi

# Remove any dot or extension provided as part of the command argument
# $1 represents the first argument passed to the script
full_name="$1"

# Removes the shortest match from the end of the string
clean_name="${full_name%.*}"

# File Names from command line arguement
INPUT="${clean_name}"
INPUT_WAV="${clean_name}.wav"
TEMP1_WAV="${clean_name}_TEMP1.wav"
TEMP2_WAV="${clean_name}_TEMP2.wav"
RAW_WAV="${clean_name}_RAW.wav"
MSTR_WAV="${clean_name}_MSTR.wav"
COMP_WAV="${clean_name}_COMP.wav"
MP3_VER="${clean_name}.mp3"
MP4_FB="${clean_name}_FB.mp4"
MP4_YT="${clean_name}_YT.mp4"

# Graphic files we will use and create
ALBUM_ART="${clean_name}.jpg"
YT_ART="${clean_name}_YT.jpg"
MP3_ART="${clean_name}_MP3.jpg"
MP4_ART="${clean_name}_MP4.jpg"

# Colors for the terminal interaction
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
RESET=$'\e[0m'

# Example use:
#
# echo -e "Status: ${GREEN}SUCCESS${RESET}"
# echo -e "Warning: ${YELLOW}FAILED${RESET}"

# Configuration Variable for LUFS Routine
# (adjust these targets as needed)
TARGET_I="-14"      # Target Integrated Loudness (LUFS)
TARGET_TP="-1.5"    # Target True Peak (dBTP)
TARGET_LRA="11"     # Target Loudness Range (LU)

# Integrated LUFS (Loudness Units Full Scale)
# Integrated LUFS measures the overall perceived loudness of your entire track.
# Choose your target based on your production goals:
#   -14 LUFS The Spotify Target is their reference point for "Normal" normalization.
#            If you master precisely here, your track will experience minimal volume
#            adjustment by the platform. This is ideal for acoustic, jazz, classical,
#            or highly dynamic music.
#   -7 to -10 LUFS Range of Commercial Targets with mixed opinions. Standard practice
#             on forums like Reddit suggest that pop, rock, EDM, and hip-hop are almost
#             never uploaded at -14 LUFS. Producers usually push these genres to a range
#             of -7 to -10 LUFS to maintain competitive density and compression.
# Note on Normalization: If you upload at -8 LUFS, Spotify will turn your track down by
# 6 dB so it matches everything else.
#
# dBTP (Decibels True Peak)
# True Peak is critical because Spotify transcodes your WAV file into lossy formats like
# Ogg Vorbis and AAC. This encoding process creates inter-sample peaks that can cause
# digital clipping. Spotify provides two distinct guidelines based on your integrated
# loudness:
#    -1 dBTP: Use this ceiling only if your master is at or below -14 LUFS.
#    -2 dBTP: Use this ceiling if your master is louder than -14 LUFS (e.g., -9 LUFS).
#             Loud, heavily limited music overshoots much harder during transcoding.
#             Leaving 2 dB of headroom ensures your music won't distort on the listener’s
#             speakers.
#
# LU (Loudness Units / Dynamic Range)
# LU refers to the Loudness Range (LRA) or the relative dynamic contrast within the song.
#    8 to 10 LU is a healthy target for mainstream, commercial music. It provides enough
#               punch and dynamic variation between your verses and choruses without
#               sounding like an un-dynamic "brick wall" of sound.
#    A lower value (e.g., 5 to 6 LU) means a highly compressed, consistently loud track,
#    while a higher value (12+ LU) indicates a highly dynamic mix.


# Get the current year for MP3 tagging
CURRENT_YEAR=$(date +%Y)

# Set the artist name and get the track name...
# Prompt the user for input
read -p "${GREEN}What is the name of the artist (default is 'The Daft Spaniels')? ${RESET}" input

# If 'input' is empty, use default
group_name=${input:-"The Daft Spaniels"}

read -p "${GREEN}What is the title of this track? ${RESET}" track_name

TRACK_NAME="${group_name} - ${track_name}"
echo

# Exit immediately if a command exits with a non-zero status
set -e

# Print statistics for input file
echo "Gathering file information for ${INPUT_WAV}..."

soxi "${INPUT_WAV}"

echo "Note: Typically this shows a sample rate of 48 kHz."
echo
read -r -n 1 -s -p "${GREEN}Press any key to continue...${RESET}"
echo
echo

# Resample since most of the world prefers 44.1 kHz sampling
# and use the -v flag for best quality
echo "Converting sampling rate and providing file information for ${RAW_WAV}..."
echo

sox "${INPUT_WAV}" "${RAW_WAV}" rate -v 44100

echo "Gathering file information for ${RAW_WAV}..."

soxi "${RAW_WAV}"

read -r -n 1 -s -p "${GREEN}Press any key to continue...${RESET}"
echo
echo

# Show results for output file.
echo "Showing sound level information for ${RAW_WAV}..."
echo

sox "${RAW_WAV}" -n stat

echo
read -r -n 1 -s -p "${GREEN}Press any key to proceed to end fade verification...${RESET}"
echo
echo

# Check for fade at end of track
#
# I have had issues with one track that just seemed to end abruptly in the middle
# of a note.

# Get RMS of the last 3 seconds vs the preceding audio
echo "Testing for ending fade of ${RAW_WAV} (last half second)..."
echo
# The negative arguments with the trim parameter say how far back
# from the end to go and the next parameter says how many seconds
# to sample.

rms_body=$(sox "$RAW_WAV" -n stat 2>&1 | sed -E 's/[[:blank:]]+/ /g' | awk '/RMS amplitude:/ {print $3}')
rms_tail=$(sox "$RAW_WAV" -n trim -.5 .5 stat 2>&1 | sed -E 's/[[:blank:]]+/ /g' | awk '/RMS amplitude:/ {print $3}')

echo "Body RMS: ${rms_body}"
echo "Tail RMS: ${rms_tail}"

echo
echo "NOTE: Each factor of 10 in RMS voltage is equal to 20 dB. If you"
echo "      see numbers like 0.2 for the body and 0.02 for the tail,"
echo "      that indicates the volume of the tail is dropping significantly."
echo "      If the tail has not dropped off, you may need to force more"
echo "      fading at the end. It is best to verify by listening in this"
echo "      case."
echo
read -r -n 1 -s -p "${GREEN}Press any key to continue...${RESET}"
echo

echo
echo "Normalizing RAW file into TEMP1 file..."

# The most common way to remove DC offset via command line these days is to apply a
# low highpass filter. This removes the 0 Hz subaudible energy (DC offset) without
# touching any audible bass.
#
# highpass 10: Cuts out everything below 10 Hz, perfectly clearing the DC offset.
#
# gain -n -1: The -n flag stands for normalization. The -1 tells SoX to scale
#             the peak amplitude to exactly -1 dBFS.

sox "$RAW_WAV" "$TEMP1_WAV"  highpass 10 gain -n -1

echo
echo "Processing TEMP1 file into MSTR file adjusting for a LUFS of -14... "

# There is a single pass way to do this (commented out), but the two pass method
# provides better results.

# ffmpeg -i input.wav -af loudnorm=I=-14:TP=-1.5:LRA=11 output.wav

# Ensure ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed or not in your PATH."
    exit 1
fi

echo
echo "=== Pass 1: Analyzing audio levels ==="

# Run the analysis pass and capture the console output containing the JSON block
FFMPEG_OUTPUT=$(ffmpeg -i "$TEMP1_WAV" -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:print_format=json" -f null - 2>&1)

# Helper function to extract JSON values using grep and sed
get_val() {
    echo "$FFMPEG_OUTPUT" | grep "$1" | sed -E 's/.*" : "([^"]*)".*/\1/'
}

# Parse the measured input statistics
MEASURED_I=$(get_val "input_i")
MEASURED_TP=$(get_val "input_tp")
MEASURED_LRA=$(get_val "input_lra")
MEASURED_THRESH=$(get_val "input_thresh")

# Verify that we actually managed to parse the statistics
if [ -z "$MEASURED_I" ]; then
    echo "Error: Failed to parse loudness analysis statistics from ffmpeg."
    exit 1
fi

echo
echo "Analysis complete:"
echo "  Measured I:      $MEASURED_I LUFS"
echo "  Measured TP:     $MEASURED_TP dBTP"
echo "  Measured LRA:    $MEASURED_LRA LU"
echo "  Measured Thresh: $MEASURED_THRESH"
echo
echo "=== Pass 2: Applying linear normalization ==="

# Execute the second pass using the captured measurements
ffmpeg -hide_banner -loglevel quiet -y -i "$TEMP1_WAV" -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:measured_i=${MEASURED_I}:measured_tp=${MEASURED_TP}:measured_lra=${MEASURED_LRA}:measured_thresh=${MEASURED_THRESH}:linear=true" "$MSTR_WAV"

echo
echo "Success! Output saved to: $MSTR_WAV"

echo
echo "Gathering Statistics for $MSTR_WAV..."

# We tested the original file, but now let's test the results.
# Run the analysis pass and capture the console output containing the JSON block
FFMPEG_OUTPUT=$(ffmpeg -i "$MSTR_WAV" -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:print_format=json" -f null - 2>&1)

# Helper function to extract JSON values using grep and sed
get_val() {
    echo "$FFMPEG_OUTPUT" | grep "$1" | sed -E 's/.*" : "([^"]*)".*/\1/'
}

# Parse the measured input statistics
MEASURED_I=$(get_val "input_i")
MEASURED_TP=$(get_val "input_tp")
MEASURED_LRA=$(get_val "input_lra")
MEASURED_THRESH=$(get_val "input_thresh")

# Verify that we actually managed to parse the statistics
if [ -z "$MEASURED_I" ]; then
    echo "Error: Failed to parse loudness analysis statistics from ffmpeg."
    exit 1
fi

echo
echo "Analysis of $MSTR_WAV complete:"
echo "  Measured I:      $MEASURED_I LUFS"
echo "  Measured TP:     $MEASURED_TP dBTP"
echo "  Measured LRA:    $MEASURED_LRA LU"
echo "  Measured Thresh: $MEASURED_THRESH"
echo


echo "NOTE: This file is going to be used where full dynamic range is"
echo "      okay such as FaceBook or YouTube. As long as things are close"
echo "      to -14 LUFS and -1.5 dBTP, you should be okay. We need to be"
echo "      more careful with the file targeted for Spotify."

echo
read -r -n 1 -s -p "${GREEN}Press any key to proceed to MP3 and MP4 file creation...${RESET}"
echo

# Create the MP3 and then add album art and tags
ffmpeg -hide_banner -loglevel quiet -y -i "${MSTR_WAV}" -c:a libmp3lame -b:a 192k "${MP3_VER}"

# There shouldn't be one, but remove image if present
eyeD3 --remove-all-images "${MP3_VER}" > /dev/null

# Also remove any stray comments
eyeD3 --remove-all-comments "${MP3_VER}" > /dev/null

echo

# Add the proper labels...
mid3v2 --artist="${group_name}" --song="${track_name}" --date "${CURRENT_YEAR}" "${MP3_VER}"

# Now add the album art
# First scale the image...
convert "${ALBUM_ART}" -resize 600x600 "${MP3_ART}"

# And add the image...
eyeD3 --add-image "${MP3_ART}:FRONT_COVER" "${MP3_VER}" > /dev/null

# We are done with the smaller thumbnail now...
rm "${MP3_ART}"

echo "${MP3_VER} has been successfully created..."
echo

# Show a summary info for the MP3 file
eyeD3 "${MP3_VER}"

echo
echo "Creating MP4 with 800x800 image and full dynamic audio range..."

# Image for first MP4
convert "${ALBUM_ART}" -resize 800x800 "${MP4_ART}"

# Command before optimation...
# ffmpeg -loop 1 -i "${ALBUM_ART}" -i "${MSTR_WAV}" -c:v libx264 -preset slow -crf 18 -c:a aac -b:a 192k -shortest "${MP4_FB}"

# Use optimized command...
#
# r 1: Sets the video frame rate to just 1 frame per second. Since the image
#      doesn't move, you don't need 30fps. This cuts down the rendering work by 95%+.
#
# -preset ultrafast: Prioritizes raw processing speed over maximum file compression.
# -vf "scale=...": A safety filter that ensures your JPG's dimensions are divisible
#                  by 2, which MP4 (libx264) strictly requires to avoid errors.

ffmpeg -hide_banner -loglevel quiet -y -loop 1 -r 1 -i "${MP4_ART}" -i "${MSTR_WAV}" -c:v libx264 -preset ultrafast -crf 23 -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:a aac -b:a 192k -shortest "${MP4_FB}"

# We are done with that scaled album art
rm "${MP4_ART}"

echo "First MP4 for FaceBook and other platforms was successfully completed."
echo
echo "Creating MP4 with 1920x1080 image and full dynamic audio range..."

# Although it seems like YouTube is becoming more 'friendly' to files with videos in
# square or older aspect ratios, for a while they wanted thing in 1080i format. Because
# of that, we will create a special MP4 file for use on that platform.

# Image for second MP4
convert "${ALBUM_ART}" \( +clone -resize 1920x1080\! -blur 0x30 \) +swap -resize x1080 -gravity center -composite "${YT_ART}"

# Create the file the same way as we did the first one
ffmpeg -hide_banner -loglevel quiet -y -loop 1 -r 1 -i "${YT_ART}" -i "${MSTR_WAV}" -c:v libx264 -preset ultrafast -crf 23 -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:a aac -b:a 192k -shortest "${MP4_YT}"

# We are done with that scaled album art
rm "${YT_ART}"

echo "Second MP4 for YouTube was successfully completed."

echo
read -r -n 1 -s -p "${GREEN}Press any key to proceed to creation of WAV file with Compression...${RESET}"
echo

# Now we will create a WAV file suitable for upload to Spotify.
#
# This uses compression which reduces the dynamic range of the audio with
# the result being that people listening on small phones or in moving cars
# will feel less need to tweak the playback volume between 'soft' and 'loud'
# portions of the song.
#
# Or, as someone once said, "Your mix doesn't need to sound good in the
# studio. It needs to survive in a car with one blown speaker."

echo
echo "File TEMP1 has the audio normalized to -1 dB and will the starting point..."

# Compression Parameters for the sox command.
#
# .0.05,0.2: (Attack,Decay) Standard, highly responsive timings.
#            50ms attack to catch transients and 200ms decay to smoothly release.
#
# -75,-75: Anything below the -75 dB noise floor remains uncompanded (1:1 ratio).
#
# -16,-16: Establishes the -16 dB threshold. From -75 dB up to -16 dB, the audio
#          passes through normally without compression.
#
# 0,-10.67: Defines the 3:1 compression curve above the threshold. An input signal
#           jumping from -16 dB to 0 dB represents a 16 dB increase. At a 3:1 ratio,
#           the output should only increase by 5.33 dB (\(16 \div 3\)), landing
#           exactly at -10.67 dB (\(-16 + 5.33\)).

# sox ${TEMP1_WAV} ${TEMP2_WAV} compand 0.05,0.2 -75,-75,-16,-16,0,-10.67

# Multiband Compresson works best for music.
#
# This splits the audio at 800 Hz.
# The low frequencies (below 800Hz—bass and kick drums) get a super fast attack (0.005) to keep the low-end tight.
# The high frequencies (above 800Hz—vocals and guitars) get a smoother 0.01 attack and a harder compression curve.

sox ${TEMP1_WAV} ${TEMP2_WAV} mcompand "0.005,0.1 6:-60,-40,0,-10" 800 "0.01,0.2 6:-60,-40,0,-6"

echo "File TEMP2 now has compressed audio."
echo "Processing TEMP2 file into COMP file adjusting for a LUFS of -14... "

# This uses pretty much the same code as we used with the
# uncompressed file.

echo
echo "=== Pass 1: Analyzing audio levels ==="

# Run the analysis pass and capture the console output containing the JSON block
FFMPEG_OUTPUT=$(ffmpeg -i "$TEMP2_WAV" -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:print_format=json" -f null - 2>&1)

# Helper function to extract JSON values using grep and sed
get_val() {
    echo "$FFMPEG_OUTPUT" | grep "$1" | sed -E 's/.*" : "([^"]*)".*/\1/'
}

# Parse the measured input statistics
MEASURED_I=$(get_val "input_i")
MEASURED_TP=$(get_val "input_tp")
MEASURED_LRA=$(get_val "input_lra")
MEASURED_THRESH=$(get_val "input_thresh")

# Verify that we actually managed to parse the statistics
if [ -z "$MEASURED_I" ]; then
    echo "Error: Failed to parse loudness analysis statistics from ffmpeg."
    exit 1
fi

echo
echo "Analysis complete:"
echo "  Measured I:      $MEASURED_I LUFS"
echo "  Measured TP:     $MEASURED_TP dBTP"
echo "  Measured LRA:    $MEASURED_LRA LU"
echo "  Measured Thresh: $MEASURED_THRESH"
echo
echo "=== Pass 2: Applying linear normalization ==="

# Execute the second pass using the captured measurements
ffmpeg -hide_banner -loglevel quiet -y -i "$TEMP2_WAV" -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:measured_i=${MEASURED_I}:measured_tp=${MEASURED_TP}:measured_lra=${MEASURED_LRA}:measured_thresh=${MEASURED_THRESH}:linear=true" "$COMP_WAV"

echo
echo "Success! Output saved to: $COMP_WAV"

echo
echo "Gathering Statistics for $COMP_WAV..."

# Run the analysis pass and capture the console output containing the JSON block
FFMPEG_OUTPUT=$(ffmpeg -i "$COMP_WAV" -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:print_format=json" -f null - 2>&1)

# Helper function to extract JSON values using grep and sed
get_val() {
    echo "$FFMPEG_OUTPUT" | grep "$1" | sed -E 's/.*" : "([^"]*)".*/\1/'
}

# Parse the measured input statistics
MEASURED_I=$(get_val "input_i")
MEASURED_TP=$(get_val "input_tp")
MEASURED_LRA=$(get_val "input_lra")
MEASURED_THRESH=$(get_val "input_thresh")

# Verify that we actually managed to parse the statistics
if [ -z "$MEASURED_I" ]; then
    echo "Error: Failed to parse loudness analysis statistics from ffmpeg."
    exit 1
fi

echo
echo "Analysis of $COMP_WAV complete:"
echo "  Measured I:      $MEASURED_I LUFS"
echo "  Measured TP:     $MEASURED_TP dBTP"
echo "  Measured LRA:    $MEASURED_LRA LU"
echo "  Measured Thresh: $MEASURED_THRESH"
echo

echo "NOTE: The results should be within 0.5 dB of our targets."
echo

read -r -n 1 -s -p "${GREEN}Press any key for final file cleanup and renaming...${RESET}"
echo
echo

# Remove Temp Files
rm $TEMP1_WAV
rm $TEMP2_WAV

echo "Original files ${INPUT_WAV} and ${ALBUM_ART} remained unchanged."
echo

mv "$RAW_WAV" "${TRACK_NAME}_RAW.wav"
echo "${TRACK_NAME}_RAW.wav has a sample rate of 44.1kHz."

mv "$MSTR_WAV" "${TRACK_NAME}_MSTR.wav"
echo "${TRACK_NAME}_MSTR.wav is normalized to -1 dB with full dynamic range."

mv "$COMP_WAV" "${TRACK_NAME}_COMP.wav"
echo "${TRACK_NAME}_COMP.wav has the compressed audio for streaming services."

mv "$MP3_VER" "${TRACK_NAME}.mp3"
echo "${TRACK_NAME}.mp3 is the MP3 file with tags and album art."

mv "$MP4_FB" "${TRACK_NAME}.mp4"
echo "${TRACK_NAME}.mp4 has the square album art for social media."

mv "$MP4_YT" "${TRACK_NAME}_YT.mp4"
echo "${TRACK_NAME}_YT.mp4 has album art streched for YouTube."

# For each of my songs, I also create a lyrics sheet. I write all of the
# lyrics and this provides a standard format to archive them along with
# everything else after I upload the music to the various platforms.
echo
echo "NOTE: Remember to create a Lyrics Sheet for this song."

echo
echo "All processing is complete!"
