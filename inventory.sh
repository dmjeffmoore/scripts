#!/bin/bash

# Dependencies: tree
# Description: This script will create a rolling log of the directory tree structure of /disks to keep a record of what files existed on each disk in case of drive failure.


pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

for disk in disk1 disk2 disk3 disk4; do
    pushd "/var/log/inventory/$disk"

    # delete the oldest log by modification time if there is a diskx.log.4
    for file in *; do
        if [ "${file: -1}" == "4" ]
        then
            rm "$(ls -t | tail -1)"
            #echo "Removing oldest log file"
        fi
    done

    # rename log files starting with diskx.log.4, then rename diskx.log to
    # diskx.log.1
    for i in 4 3 2 1; do
        FILE=$(find . -name *.$i)
        FILE="${FILE:2}"
        N1=${FILE%?}
        ((INC=$i+1))
        NEW_NAME="$N1$INC"
        mv $FILE $NEW_NAME &> /dev/null
        #echo "Renaming $FILE to $NEW_NAME"
    done
    mv "$disk.log" "$disk.log.1" &> /dev/null
    #echo "Renaming $disk.log to $disk.log.1"

    # create the new file that contains the disk's inventory
    tree "/disks/$disk" > "$disk.log"
    #echo "Writing to $disk.log"

    popd
done
