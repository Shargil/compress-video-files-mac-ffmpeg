#!/bin/bash

# I put ffmpeg for mac statc build in Applications
export PATH=$PATH:/Applications

fix_drag_and_drop_to_tar_adds_backslashes()
{
    # ${var//oldstring/newstring}
    # Replace "\ " with " " in the string (when we drag and drop a file to the terminal the spaces in the path become "\ ". Let's reverse that)
    user_input=${user_input//\\ / }
    # Replace "\," with "," in the string (when we drag and drop a file to the terminal the commas in the path become "\,". Let's reverse that)
    user_input=${user_input//\\,/,}
    # Replace \' with ' in the string (when we drag and drop a file to the terminal the single quats (or double) in the path become \' Let's reverse that)
    user_input=${user_input//\\\'/\'}

    # other chats it can happen with: $,(,),[,],{,},!,<,>,&,',",;,*,?,#,%,|,~,\,/,\
}

user_inputs=""
user_input=""
while [[ $user_input != Start ]] ; do
    echo "Drag and drop .MOV video files for compression, when finished type Start"
    read -r user_input
    if [[ $user_input != Start ]]
    then 
        fix_drag_and_drop_to_tar_adds_backslashes
        
        # Replace ".mov" with ".MOV" for the delimeter to work
        user_input=${user_input//.mov/.MOV}

        user_inputs+=$user_input
    fi
done

# Separte long str into separate pathes array
# https://www.javatpoint.com/bash-split-string#:~:text=Example%202%3A%20Bash-,Split%20String%20by%20another%20string,-In%20this%20example
delimiter=".MOV" 
s=$user_inputs
pathes_array=();  
while [[ $s ]];  
do  
    pathes_array+=( "${s%%"$delimiter"*}" );  
    s=${s#*"$delimiter"};  
done;  

# Compress all files!
for ((i = 0; i < ${#pathes_array[@]}; i++))
do
    path=${pathes_array[$i]}.MOV

    # Remove a leading space, if present
    path=${path# }

    echo "--------------------------------------------------------------------------------"
    echo "$path"
    echo "--------------------------------------------------------------------------------"

    # If the file ends with .MOV 
    if [[ .MOV == "${path:0-4}" ]]
    then
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

    else
	    echo "Is this this the right file? No .MOV file extention : $path" 
    fi
done

echo "---------------------------------- Done! ---------------------------------------"
echo "Check there are the same amount of files in the Originals folder as the compressed files"
echo "Check some random videos to see it's all good!"
echo "Only after checking all is good, you can DELETE Originals... "
echo "--------------------------------------------------------------------------------"


# -------- pseudo code --------
# loop thourgh inputs
    # drag and drop all videos you want to compress
    # add it to list/ dict

# loop through files
    # if video
        # compress "samename_compressed."
        # ffmpeg -i input.mp4 -vcodec libx265 -crf 28 output.mp4
        # copy exif data + modifed date 
        # move original to "originals - delete if all went OK"