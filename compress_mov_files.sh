#!/bin/bash

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

# Compress all files!
for ((i = 0; i < ${#pathes_array[@]}; i++))
do
    path=${pathes_array[$i]}

    # Remove a leading space, if present
    path=${path# }

    echo "--------------------------------------------------------------------------------"
    echo "$path"
    echo "--------------------------------------------------------------------------------"

    # Compress file to the same path

    # -movflags use_metadata_tags = copy all metadata 
    # -loglevel warning           = Remove crazy amounts of prints to terminal, so it's viable to go thourgh it later and check for erros
    # -hide_banner                = Suppress printing copyright notice, build options and library versions
    # libx265                     = new better verstion of h264
    # -crf 24                     = reasonable range for H.265 may be 24 to 30. Note that lower CRF values correspond to higher bitrates, and hence produce higher quality videos.
    # -tag:v hvc1                 = fix a tagging problem blocking QuickTime from opeing the video
    # "${path%.*}"                = remove everything after and including the final "."
    ffmpeg -i "$path" -movflags use_metadata_tags -loglevel warning -hide_banner -vcodec libx265 -crf 24 -tag:v hvc1 "${path%.*}"_compressed.mp4

    #  Copy the timestamp of the original file to the new one
    touch -r "$path" "${path%.*}"_compressed.mp4

    # Create the originals folder if doesn't exsit all ready
    mkdir -p -- "${path%/*}/Original Files - DELETE if all went OK"
    
    # Move original file to folder "Original Files - DELETE if all went OK"
    mv -v "$path"  "${path%/*}/Original Files - DELETE if all went OK"
done

echo "---------------------------------- Done! ---------------------------------------"
echo "Check there are the same amount of files in the Originals folder as the compressed files"
echo "Check some random videos to see it's all good!"
echo "Only after checking all is good, you can DELETE Originals... "
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