#!/bin/bash

# Description: This script will go through all files within the current directory and rename files
# that result from the  mv --backup=numbered <source_file> <dest_file> to a name that keeps the original file extension.

for file in *; do
    if [ ! -d "$file" ]; then
        EXT=$(echo "$file" | cut -d '.' -f 3)
        if [[ $EXT == "~"* ]]; then
            FILE_NAME=$(echo "$file" | cut -d '.' -f 1)
            EXTENSION=$(echo "$file" | cut -d '.' -f 2)
            UNDERSCORE="_"
            DOT="."
            NUM=$(echo "$file" | cut -d '.' -f 3 | cut -d '~' -f 2)
            NEW_NAME="$FILE_NAME$UNDERSCORE$NUM$DOT$EXTENSION"
            mv "$file" $NEW_NAME
            echo "$file renamed to $NEW_NAME"
        fi
    fi
done

echo "Done!"
