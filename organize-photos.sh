#!/bin/bash

# Dependencies: exiftool
# Description: This script will organize all jpg,JPG,jpeg,png,gif files into folders by year then by month. Just put this script
# into the folder where all your unsorted photos are located and run it. While it is running, it will move pictures into ../Sorted
# using the earliest date in the file's EXIF metadata.

IFS=''
NUM_FILES_IN_CURR_DIR=$(expr $(ls | wc -l) - 1) # count the number of photos in the current directory minus the script itself

for file in *.{jpg,JPG,jpeg,png,gif}; do
    [ -f "$file" ] || break
    MIN_YEAR_MONTH=400000

    if exiftool -a -G1 -s -time:all $file > /dev/null # check if the exiftool command is successful on the file
    then
        while read -r line
        do
            YEAR_MONTH=$(echo $line | cut -d ':' -f2,3 | xargs | sed 's/://')
            NUM_SEMICOLONS_IN_LINE=$(awk -F":" '{print NF-1}' <<< "${line}")

            re='^[[:digit:]]+$' # regex for digits

            # check if the YEAR_MONTH string has more than 5 characters, that it only contains digits,
            # and that the line does not contain ProfileDateTime which is a timestamp that we want to omit
            # as it's not related to the file
            if [ ${#YEAR_MONTH} -gt 5 ] && [[ $YEAR_MONTH =~ $re ]] && [ $NUM_SEMICOLONS_IN_LINE -gt 4 ] && [[ $line != *"ProfileDateTime"* ]]; then
                if ([ $MIN_YEAR_MONTH -eq 400000 ] || [ $YEAR_MONTH -lt $MIN_YEAR_MONTH ]) && [ $YEAR_MONTH -ne 000000 ]; then
                    MIN_YEAR_MONTH=$YEAR_MONTH
                fi
            fi
        done < <(exiftool -a -G1 -s -time:all $file)

        if [ $MIN_YEAR_MONTH -ne 400000 ]
        then
            YEAR_MONTH=$(echo $MIN_YEAR_MONTH | sed 's/^\(.\{4\}\)/\1:/') # add the ':' to seperate the year and the month
            YEAR=$(echo $YEAR_MONTH | cut -d ':' -f 1)
            MONTH=$(echo $YEAR_MONTH | cut -d ':' -f 2)
            if [ $MONTH == 0* ]; then
                MONTH="${MONTH:1}"
            fi

            [ ! -d "../Sorted/$YEAR/$MONTH" ] && mkdir -p "../Sorted/$YEAR/$MONTH"
            mv $file ../Sorted/$YEAR/$MONTH
        else
            >&2 echo "Failed to get earliest date from EXIF data for $file"
        fi
    else
        >&2 echo "Failed to extract EXIF data from $file"
    fi

    NUM_FILES_IN_SORTED_DIR=$(find ../Sorted -type f | wc -l)
    percent=$(echo "scale=2;$NUM_FILES_IN_SORTED_DIR / $NUM_FILES_IN_CURR_DIR" | bc -l)
    percent="${percent:1}"
    echo -ne "progress: $percent%\r"
done

echo -ne "\n"
exit 0
