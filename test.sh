#!/bin/bash

# Source the autocomplete script
source ./python_argparse_complete.sh

# Function to simulate pressing Tab
simulate_tab() {
    local command="$1"
    echo "Testing: $command"
    COMP_WORDS=($command)
    COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
    COMP_LINE="$command"
    COMP_POINT=${#COMP_LINE}

    echo "Debug: COMP_WORDS=${COMP_WORDS[@]}"
    echo "Debug: COMP_CWORD=$COMP_CWORD"
    echo "Debug: COMP_LINE=$COMP_LINE"
    echo "Debug: COMP_POINT=$COMP_POINT"

    _python_script_autocomplete

    if [ ${#COMPREPLY[@]} -eq 0 ]; then
        echo "No completions"
    else
        echo "Completions: ${COMPREPLY[@]}"
    fi
    echo
}

# Test cases
simulate_tab "python sample_script.py --"
simulate_tab "python sample_script.py --in"
simulate_tab "python sample_script.py --input file.txt --"
simulate_tab "python sample_script.py --input file.txt --verb"

# Debug: print contents of sample_script.py
echo "Debug: Contents of sample_script.py:"
cat sample_script.py
