#!/bin/bash

FILE="$1"

# Make sure a file was provided
if [ -z "$FILE" ]; then
    echo "No Typst file provided"
    exit 1
fi

# Make sure it exists
if [ ! -f "$FILE" ]; then
    echo "File does not exist: $FILE"
    exit 1
fi

# Get absolute paths
FILE="$(cd "$(dirname "$FILE")" && pwd)/$(basename "$FILE")"
DIR="$(dirname "$FILE")"
NAME="$(basename "$FILE" .typ)"

PDF="$DIR/$NAME.pdf"

# ------------------------------------------------------------
# Compile the PDF once
# ------------------------------------------------------------

typst compile "$FILE" "$PDF"

if [ $? -ne 0 ]; then
    echo "Typst compilation failed"
    exit 1
fi

# ------------------------------------------------------------
# Make sure PDF actually exists
# ------------------------------------------------------------

if [ ! -f "$PDF" ]; then
    echo "PDF was not created: $PDF"
    exit 1
fi

# ------------------------------------------------------------
# Start live recompilation
# ------------------------------------------------------------

typst watch "$FILE" "$PDF" \
    >/tmp/typst-watch.log 2>&1 &

# ------------------------------------------------------------
# Open the generated PDF
# ------------------------------------------------------------

zathura "$PDF"
