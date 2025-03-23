#!/bin/bash

if [ "$#" -lt 2 ]; then
	echo "Usage: $0 output_file file1 file2 ..."
	exit 1
fi

output_file="$1"
shift

if [ -f "$output_file" ]; then
	echo "$0: File $output_file already exists"
	echo "$0: Would you like to overwrite it? [Y/n]"
	read -r answer
	if [ -z "$answer" ]; then
		answer="Y"
	fi
	if [ "$answer" != "Y" ] && [ "$answer" != "y" ]; then
		echo "$0: Aborting"
		exit 1
	else
		echo "$0: Overwriting $output_file"
	fi
else
	echo "$0: Creating $output_file"
	touch "$output_file"
fi

for file in "$@"; do
	if [ ! -f "$file" ]; then
		echo "$0: File $file does not exist"
		exit 1
	fi
done

echo "$0: Merging files into $output_file"
awk 'FNR==1 {
if (NR!=1) print "---------";
    print "";
    cmd = "dirname " FILENAME;
    cmd | getline dir;
    close(cmd);
    print dir;
    print ""
}
{print}' "$@" >"$output_file"
echo "$0: Done"
