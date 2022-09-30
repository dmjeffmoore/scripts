#!/bin/bash

# Dependencies: exiftool
# Description: This script will organize all photos and videos into folders by year then by month. Just put this script
# into the folder where all your unsorted photos are located and run it. While it is running, it will move pictures into ../Sorted
# using the earliest date in the file's EXIF metadata.

IFS=''
DIGITS_REGEX='^[[:digit:]]+$'

NUM_FILES_IN_CURR_DIR=$(expr $(ls | wc -l) - 1) # count the number of photos in the current directory minus the script itself
echo "Sorting $NUM_FILES_IN_CURR_DIR files..."

for file in *.{jpg,JPG,jpeg,png,PNG,gif,MTS,mp4,MP4,mov,MOV,AVI,HEIC,heic}; do
    if [ ! -d "$file" ]; then
        MIN_YEAR_MONTH=400000

        if exiftool -a -G1 -s -time:all "$file" > /dev/null # check if the exiftool command is successful on the file
        then
            while read -r line
            do
                YEAR_MONTH=$(echo $line | cut -d ':' -f2,3 | xargs | sed 's/://')
                NUM_SEMICOLONS_IN_LINE=$(awk -F":" '{print NF-1}' <<< "${line}")

                if [ ${#YEAR_MONTH} -gt 5 ] && [[ $YEAR_MONTH =~ $DIGITS_REGEX ]] && [ $YEAR_MONTH -gt 199000 ] && [ $NUM_SEMICOLONS_IN_LINE -gt 4 ] && [[ $line != *"ProfileDateTime"* ]] && [[ $line != *"GPS"* ]] && [[ $line != *"FlashPix"* ]]; then
                    if ([ $MIN_YEAR_MONTH -eq 400000 ] || [ $YEAR_MONTH -lt $MIN_YEAR_MONTH ]) && [ $YEAR_MONTH -ne 000000 ]; then
                        MIN_YEAR_MONTH=$YEAR_MONTH
                    fi
                fi
            done < <(exiftool -a -G1 -s -time:all "$file")

            if [ $MIN_YEAR_MONTH -ne 400000 ]
            then
                YEAR_MONTH=$(echo $MIN_YEAR_MONTH | sed 's/^\(.\{4\}\)/\1:/') # add the ':' to seperate the year and the month
                YEAR=$(echo $YEAR_MONTH | cut -d ':' -f 1)
                MONTH=$(echo $YEAR_MONTH | cut -d ':' -f 2)

                [ ! -d "../Sorted/$YEAR/$MONTH" ] && mkdir -p "../Sorted/$YEAR/$MONTH"
                mv "$file" ../Sorted/$YEAR/$MONTH
                NUM_FILES_IN_CURR_DIR=$(expr $(ls | wc -l) - 1) # count the number of photos in the current directory minus the script itself
                echo "Moved $file, $NUM_FILES_IN_CURR_DIR files left"
            else
                >&2 echo "Failed to get earliest date from EXIF data for $file"
            fi
        else
            >&2 echo "Failed to extract EXIF data from $file"
        fi
    fi
done

echo "Done!"
exit 0
