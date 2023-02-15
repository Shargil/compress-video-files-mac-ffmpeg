#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# I placed ffmpeg for mac static build in Applications
export PATH=$PATH:/Applications

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null
then
    echo "ffmpeg is not installed. Please install ffmpeg and try again."
    exit 1
fi

# Check if exiftool is installed
if ! command -v exiftool &> /dev/null
then
    echo "exiftool is not installed. Please install exiftool and try again."
    exit 1
fi

# Get the folder path
folder_path="$1"

# Check if the path is a directory
if [ ! -d "$folder_path" ]
then
    echo "The path provided is not a directory. Please provide a valid directory path."
    exit 1
fi

# Create a subfolder for original files
original_folder="$folder_path/original_for_delete"
if [ ! -d "$original_folder" ]
then
    mkdir "$original_folder"
fi

# Seprate files with pathes that containes spaces corectly https://unix.stackexchange.com/questions/9496/looping-through-files-with-spaces-in-the-names
OIFS="$IFS"
IFS=$'\n'

# Find all photo files in the folder and its subfolders
photo_files=($(find "$folder_path" -type f \( -name "*.jpg" -o -name "*.JPG" -o -name "*.jpeg" -o -name "*.JPEG" -o -name "*.png" -o -name "*.PNG" -o -name "*.gif" -o -name "*.GIF" \)))


# Loop through each photo file
count=0
total="${#photo_files[@]}"
original_size=0
new_size=0
files_with_ffmpeg_errors=()

for photo_file in "${photo_files[@]}"
do
    count=$((count+1))
    echo "------------------------------------- $count/$total -------------------------------------"
    echo "File: $photo_file"
    echo "--------------------------------------------------------------------------------"

    new_photo_file="${photo_file%.*}"_compressed.jpg

    # -loglevel warning           = Remove crazy amounts of prints to terminal, so it's viable to go thourgh it later and check for erros
    # -hide_banner                = Suppress printing copyright notice, build options and library versions
    # -q:v 10                     = The output quality. Lower numbers means better quality and bigger files. -q:v 10 means to compress to 10th of the size.    
    # Compress the photo file
    ffmpeg -i "$photo_file" -loglevel warning -hide_banner -q:v 10 "$new_photo_file"

    # Check if ffmpeg ran successfully by checking its exit code
    if [ $? -ne 0 ]
    then
        files_with_ffmpeg_errors+=("$photo_file")
    else 

        # Copy most meta data. Including create date (important for files with no "media created date" and with "date modified" that not showing creation date any more [which is valid])
        exiftool -TagsFromFile "$photo_file" -All:All -overwrite_original "$new_photo_file"

        # Copy the File Modification Date/Time from original file (Finder in macos uses "Date Modified" as one of his main columns as default)
        touch -r "$photo_file" "$new_photo_file"

        # Count the original and the new files sizes to show in the end!
        original_size=$((original_size + $(wc -c < "$photo_file")))
        new_size=$((new_size + $(wc -c < "$new_photo_file")))

        # Move the original file to the "original_for_delete" folder
        mv "$photo_file" "$original_folder"

    fi
done

# Changing the Internal Field Separator back
IFS="$OIFS"

# Error summary
if [ ${#files_with_ffmpeg_errors[@]} -ne 0 ]; then
    echo "---------------------------------- Errors! ---------------------------------------"
    echo " There are ${#files_with_ffmpeg_errors[@]} errors"
    echo " In the following files: "
        for i in "${files_with_ffmpeg_errors[@]}"; do
            echo -e "       ${RED} Error with: $i ${NC}"
        done
fi

# Summary
original_size_GB=$(echo "scale=2; $original_size / 1000000000" | bc) # It matches Mac's finder size info better then 1024^3
new_size_GB=$(echo "scale=2; $new_size / 1000000000" | bc)
compress_ratio=$(echo "scale=2; $original_size/$new_size" | bc)
echo "---------------------------------- Done! ---------------------------------------"
echo -e "${GREEN} Original files size: $original_size_GB GB | New files size: $new_size_GB GB${NC}"
echo -e "${GREEN} You made the size $compress_ratio times smaller!${NC}"
echo "                                                                                "
echo " Check all went well before you DELETE originals folder: "
echo "  1. Check some random photos to see if they look good "
echo "  2. Scroll through the terminal to check for any colorful errors "
echo "--------------------------------------------------------------------------------"