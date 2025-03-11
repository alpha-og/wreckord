#!/bin/bash

# Ensure jq is installed
if ! command -v jq &>/dev/null; then
	echo "jq is required but not installed. Please install jq and try again."
	exit 1
fi

# JSON file path
JSON_FILE="experiments.json"
# Output directory
OUTPUT_DIR="out"
# Program file name
# DATA_PROGRAM_FILE_NAME="code.sh"
# Output image file prefix
DATA_SS_FILE_PREFIX="o-"
# template for code
CODE_TEMPLATE="\inputminted[fontsize=\small,breaklines,breakanywhere]{<ft>}{<code_file>}%program name"
# template for output screenshot
OUTPUT_SS_TEMPLATE="\includegraphics[width=\\textwidth]{<output>}"
# template for page
PAGE_TEMPLATE="$(cat "$PWD/page_template.tex")"
#template for doc
DOC_TEMPLATE="$(cat "$PWD/doc_template.tex")"

# template strings
TEMPLATE_STRING_TITLE="<title>"
TEMPLATE_STRING_AIM="<aim>"
TEMPLATE_STRING_ALGORITHM="<algorithm>"
TEMPLATE_STRING_CODE="<code>"
TEMPLATE_STRING_OUTPUT="<output>"
TEMPLATE_STRING_RESULT="<result>"

# Check if output directory exists and create it if not
if [ ! -d "$OUTPUT_DIR" ]; then
	echo "Creating output directory '$OUTPUT_DIR'..."
	mkdir "$OUTPUT_DIR"
else
	echo "Output directory '$OUTPUT_DIR' already exists."
	echo "Would you like to clear the cache and regenerate all documents? (y/n)"
	read -r clear_cache
	if [ "$clear_cache" = "y" ]; then
		echo "Clearing cache..."
		rm -rf "$OUTPUT_DIR"
	fi
fi

# Check if file exists
if [ ! -f "$JSON_FILE" ]; then
	echo "Error: JSON file '$JSON_FILE' not found."
	exit 1
fi

# output merged algorithms
./merge.sh ./out/algorithms.txt p*/algorithm.txt

# output merged aims
./merge.sh ./out/aims.txt p*/aim.txt

# Loop through each experiment in the JSON file
jq -c '.experiments[]' "$JSON_FILE" | while read -r experiment; do
	# Extract fields from each experiment
	pid=$(echo "$experiment" | jq -r '.pid')
	title=$(echo "$experiment" | jq -r '.title')
	# aim=$(echo "$experiment" | jq -r '.aim')
	# algorithm=$(echo "$experiment" | jq -r '.algorithm')
	result=$(echo "$experiment" | jq -r '.result')

	echo "Generating page for experiment $title (problem $pid)..."
	directory="p$pid"
	if [ ! -d "$directory" ]; then
		echo "Error: Directory '$directory' not found."
		exit 1
	fi

	# Generate aim
	aim=$(cat "$directory/aim.txt")

	# Generate algorithm
	algorithm="$(cat "$directory/algorithm.txt")"
	if [[ "$pid" -ge 1 && "$pid" -le 10 ]]; then
		ft="sh"
	else
		ft="c"
	fi

	# Generate filled template for code
	code_file="./$directory/code.$ft"
	if [ ! -f "$code_file" ]; then
		echo "Error: Code file '$code_file' not found."
		# exit 1
	fi

	code_filled_template=${CODE_TEMPLATE//<code_file>/$code_file}
	code_filled_template=${code_filled_template//<ft>/$ft}

	# Generate filled tempalte for output screenshot
	output_ss_files=$(echo "$directory/$DATA_SS_FILE_PREFIX"*)
	if [ -z "$output_ss_files" ]; then
		echo "Error: No output files found in directory '$directory'."
		exit 1
	fi
	echo "Using code file '$code_file' and output files '$output_ss_files'."

	output_ss_filled_template=""

	for output_ss_file in $output_ss_files; do
		# Generate filled output ss template
		output_ss_file="./$output_ss_file"
		output_ss_filled_template+="${OUTPUT_SS_TEMPLATE//<output>/$output_ss_file}"$'\n'
	done

	# Generate output file
	output_subdir="$OUTPUT_DIR/p$pid"
	if [ ! -d "$output_subdir" ]; then
		echo "Creating output directory '$output_subdir'..."
		mkdir -p "$output_subdir"
	fi

	output_file="$output_subdir/page.tex"
	echo "Generating output file '$output_file'..."
	echo "copying dependencies..."
	cp -r "p$pid/"* "$output_subdir"

	tmp_page="$PAGE_TEMPLATE"
	tmp_page=${tmp_page//$TEMPLATE_STRING_TITLE/$title}                      # inject title
	tmp_page=${tmp_page//$TEMPLATE_STRING_AIM/$aim}                          # inject aim
	tmp_page=${tmp_page//$TEMPLATE_STRING_ALGORITHM/$algorithm}              # inject algorithm
	tmp_page=${tmp_page//$TEMPLATE_STRING_CODE/$code_filled_template}        # inject code
	tmp_page=${tmp_page//$TEMPLATE_STRING_OUTPUT/$output_ss_filled_template} # inject output
	tmp_page=${tmp_page//$TEMPLATE_STRING_RESULT/$result}                    # inject result

	echo "$tmp_page" >"$output_file"
	echo "Completed generating '$output_file'."
done

pages=$(echo "$OUTPUT_DIR/p"{2..24}"/page.tex")
echo "Generating final document..."
doc_file="$OUTPUT_DIR/doc.tex"
touch "$doc_file"
echo "$DOC_TEMPLATE" >"$doc_file"

for page in $pages; do
	echo "Processing '$page'..."
	cat "$page" >>"$doc_file"
done

echo "\end{document}" >>"$doc_file"

echo "Completed generating '$doc_file'."
