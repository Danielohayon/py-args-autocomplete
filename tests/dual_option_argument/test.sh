#!/bin/bash

# Source the autocompletion script
source ../../src/python_argparse_complete.sh

# Source bash-completion if available
if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
else
    echo "bash-completion not found. Some functions may not work."
fi

# Ensure sample_script.py is executable
chmod +x sample_script.py

# Function to simulate autocompletion
simulate_completion() {
    local cmdline="$1"
    shift
    local expected_completions=("$@")

    # Determine if there's a trailing space
    local trailing_space=0
    if [[ "$cmdline" == *" " ]]; then
        trailing_space=1
    fi

    # Split the command line into words
    # Using 'read' to handle spaces correctly
    IFS=' ' read -r -a COMP_WORDS <<< "$cmdline"

    # If there's a trailing space, add an empty word
    if [ $trailing_space -eq 1 ]; then
        COMP_WORDS+=("")
    fi

    # Set COMP_CWORD to the index of the current word
    COMP_CWORD=${#COMP_WORDS[@]}
    ((COMP_CWORD--))

    # Set cur and prev
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev
    if [ $COMP_CWORD -ge 1 ]; then
        prev="${COMP_WORDS[COMP_CWORD-1]}"
    else
        prev=""
    fi

    # Initialize COMPREPLY
    COMPREPLY=()

    # Call the autocompletion function
    _python_script_autocomplete

    # Capture the completion suggestions
    local completions=("${COMPREPLY[@]}")

    # Output the test results
    echo "Testing completion for: '$cmdline'"
    echo "Expected completions: ${expected_completions[*]}"
    echo "Actual completions: ${completions[*]}"
    echo "COMP_WORDS: ${COMP_WORDS[*]}"
    echo "COMP_CWORD: $COMP_CWORD"
    echo "cur: '$cur'"
    # Verify the completions
    local all_found=true
    for expected in "${expected_completions[@]}"; do
        if [[ ! " ${completions[*]} " =~ " $expected " ]]; then
            echo "❌ Missing expected completion: $expected"
            all_found=false
        fi
    done

    # Check for unexpected completions
    for completion in "${completions[@]}"; do
        if [[ ! " ${expected_completions[*]} " =~ " $completion " ]]; then
            echo "❌ Unexpected completion: $completion"
            all_found=false
        fi
    done

    if $all_found; then
        echo "✅ Test passed."
    else
        echo "❌ Test failed."
    fi
    echo "----------------------------------------"
}

# Test Cases

# Test 1: Suggest options after '--', including '--config'
simulate_completion "python sample_script.py --" '--input' '--output' '--verbose' '--level' '--config'

# Test 2: Suggest choices for '--input'
simulate_completion "python sample_script.py --input " 'in1' 'in2'

# Test 3: Suggest choices for '--level'
simulate_completion "python sample_script.py --level " '1' '2' '3'

# Test 4: Do not suggest already used options
simulate_completion "python sample_script.py --input in1 --" '--output' '--verbose' '--level' '--config'

# Test 6: Autocomplete suggests both -c and --config options
simulate_completion "python sample_script.py --" '--input' '--output' '--verbose' '--level' '--config'

# Test 7: Suggest choices for '--config'
simulate_completion "python sample_script.py --config " 'in1' 'in2' 'in3'

# Test 8: Suggest choices for '-c'
simulate_completion "python sample_script.py -c " 'in1' 'in2' 'in3'

simulate_completion "python sample_script.py -c in1 --" '--input' '--output' '--verbose' '--level' 

simulate_completion "python sample_script.py --config in1 -" '--input' '--output' '--verbose' '--level' 
