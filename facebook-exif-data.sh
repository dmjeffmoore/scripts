#!/bin/bash

# Dependencies: exiftool, jq
# Description: 

# TODO
# iterate through each json file
# for each json file
#  get the albumName
#  for each file in the photos array
#    get the filename and timestamp (looks like epoch milli)
#    set alldates to that date for that file

for file in *.json; do
    [ -f "$file" ] || break

    ALBUM_NAME=$(jq '.name' $file)

    jq -c '.photos[]' $file |
    while read photo; do
        echo $photo
    done

done

