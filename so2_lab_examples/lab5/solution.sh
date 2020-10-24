#!/bin/bash

search_directory=$1
output_file="results.txt"

find "$search_directory" -type f -print | while read -r file_path
do
    file_name=${file_path##*/}
    reversed_file_name=$(echo "$file_name" | rev )
    if [ "$reversed_file_name" == "$file_name" ]; then
        echo "$file_path"
    fi
done | tee "$output_file"