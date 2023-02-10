#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# I placed ffmpeg for mac static build in Applications
export PATH=$PATH:/Applications

fix_drag_and_drop_adds_backslashes()
{
    # Example: replace "\ " with " " in the string (when we drag and drop a file to the terminal the spaces in the path become "\ ". Let's reverse that)
    chars_that_gets_backslash_when_dropped=(" " "," "'" "$" "(" ")" "[" "]" "{" "}" "!" "<" ">" "&" "\"" ";" "*" "?" "#" "%" "|" "~")

    for ((i = 0; i < ${#chars_that_gets_backslash_when_dropped[@]}; i++))
    do
        special_char=${chars_that_gets_backslash_when_dropped[$i]}
        # ${var//oldstring/newstring}
        user_input=${user_input//\\$special_char/$special_char}
    done
}

user_inputs=""
user_input=""
# Check also .AVI .avi .mpg .mpeg .m4v 
supported_files=(".mov" ".MOV" ".mp4" ".MP4" ".AVI" ".avi" ".mpg" ".mpeg" ".m4v" ".wmv")

# Get all files!
echo "Drag and drop video files (${supported_files[*]}) for compression, when finished type Start"
read -r user_input
while [[ $user_input != Start ]] ; do
    
    fix_drag_and_drop_adds_backslashes

    user_inputs+=$user_input

    echo "Drag and drop video files (${supported_files[*]}) for compression, when finished type Start"
    read -r user_input
done

# Add to the specified file type a * character, so we can separte it into array of pathes
for ((i = 0; i < ${#supported_files[@]}; i++))
do
    file_type=${supported_files[$i]}
    user_inputs="${user_inputs//$file_type/$file_type*}"
done

# Separate the string into an array using the * character
IFS=$'*' read -ra pathes_array <<< "$user_inputs"


original_size=0
new_size=0
files_with_ffmpeg_errors=()
# Compress all files!
for ((i = 0; i < ${#pathes_array[@]}; i++))
do
    path=${pathes_array[$i]}

    # Remove a leading space, if present
    path=${path# }

    echo "------------------------------------- $((i + 1))\\${#pathes_array[@]} -------------------------------------"
    echo "$path"
    echo "--------------------------------------------------------------------------------"

    # Compress file to the same path

    # -movflags use_metadata_tags = copy some metadata 
    # -loglevel warning           = Remove crazy amounts of prints to terminal, so it's viable to go thourgh it later and check for erros
    # -hide_banner                = Suppress printing copyright notice, build options and library versions
    # libx265                     = new better verstion of h264
    # -crf 24                     = reasonable range for H.265 may be 24 to 30. Note that lower CRF values correspond to higher bitrates, and hence produce higher quality videos.
    # -tag:v hvc1                 = fix a tagging problem blocking QuickTime from opeing the video
    # "${path%.*}"                = remove everything after and including the final "."
    ffmpeg -i "$path" -movflags use_metadata_tags -loglevel warning -hide_banner -vcodec libx265 -crf 24 -tag:v hvc1 "${path%.*}"_compressed.mp4

    # Check if ffmpeg ran successfully by checking its exit code
    if [ $? -ne 0 ]; then
        files_with_ffmpeg_errors+=($path)
    else 
        # Copy most meta data. Including create date (important for files with no "media created date" and with "date modified" that not showing creation date any more [which is valid])
        exiftool -TagsFromFile "$path" -All:All -overwrite_original "${path%.*}"_compressed.mp4

        # Copy the File Modification Date/Time from original file (Finder in macos uses "Date Modified" as one of his main columns as default)
        touch -r "$path" "${path%.*}"_compressed.mp4

        # Count the original and the new files sizes to show in the end!
        original_size=$((original_size + $(wc -c < "$path")))
        new_size=$((new_size + $(wc -c < "${path%.*}"_compressed.mp4)))

        # Create the originals folder if doesn't exsit all ready
        mkdir -p -- "${path%/*}/Original Files - DELETE if all went OK"
        
        # Move original file to folder "Original Files - DELETE if all went OK"
        mv -v "$path"  "${path%/*}/Original Files - DELETE if all went OK"
    fi
done

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
echo "---------------------------------- Done! ---------------------------------------"
echo -e "${GREEN} Original files size: $original_size_GB GB | New files size: $new_size_GB GB${NC}"
echo "                                                                                "
echo " Check all went well before you DELETE originals folder: "
echo "  1. Check some random videos to see if they look good"
echo "  2. Check there are the same amount of files in the Originals folder as the compressed files"
echo "  3. Scroll through the terminal to check for any colorful errors "
echo "--------------------------------------------------------------------------------"


# -------- Pseudo Code --------
# loop thourgh inputs
    # drag and drop all videos you want to compress
    # add it to list/ dict

# loop through files
    # if video
        # compress "samename_compressed."
        # ffmpeg -i input.mp4 -vcodec libx265 -crf 28 output.mp4
        # copy exif data + modifed date 
        # move original to "originals - delete if all went OK"
