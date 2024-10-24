#!/bin/bash

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the autocompletion script
source "$PROJECT_ROOT/src/python_argparse_complete.sh"

# Source bash-completion if available
if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to simulate autocompletion
simulate_completion() {
    local case_dir="$1"
    local cmdline="$2"
    shift 2
    local expected_completions=("$@")

    # Save current directory
    local original_dir=$(pwd)
    
    # Change to the test case directory for file completion
    cd "$case_dir" || exit 1

    # Get the Python script name
    local script_name="$(basename "$case_dir").py"

    # Build the modified command line using relative paths
    local modified_cmdline="python ./$script_name${cmdline#*$script_name}"

    # Determine if there's a trailing space
    local trailing_space=0
    [[ "$modified_cmdline" == *" " ]] && trailing_space=1

    # Split the command line into words, preserving spaces
    read -ra COMP_WORDS <<< "$modified_cmdline"
    
    # If there's a trailing space, add an empty word
    [ $trailing_space -eq 1 ] && COMP_WORDS+=("")

    # Set COMP_CWORD to the index of the last word
    COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))

    # Get the current word being completed
    local cur="${COMP_WORDS[COMP_CWORD]}"
    
    # Get the previous word
    local prev
    if [ $COMP_CWORD -ge 1 ]; then
        prev="${COMP_WORDS[COMP_CWORD-1]}"
    else
        prev=""
    fi

    # Set COMP_LINE and COMP_POINT
    COMP_LINE="$modified_cmdline"
    COMP_POINT=${#COMP_LINE}

    # Initialize COMPREPLY
    COMPREPLY=()

    # Call the autocompletion function and capture its return code
    _python_script_autocomplete
    local completion_status=$?

    # If return code is 124, it means we should use default bash completion
    if [ $completion_status -eq 124 ]; then
        # Get completions using compgen for files in the current directory
        if [[ -n "$cur" ]]; then
            COMPREPLY=($(compgen -f -- "$cur"))
        else
            COMPREPLY=($(compgen -f))
        fi
    fi

    # Prepare debug info
    local debug_info="Debug info:
Working directory: $(pwd)
Modified command line: $modified_cmdline
COMP_WORDS: ${COMP_WORDS[*]}
COMP_CWORD: $COMP_CWORD
cur: '$cur'
prev: '$prev'
Completion status: $completion_status
Files in directory: $(ls)"

    # Verify the completions while still in the correct directory
    local test_failed=0  # Use 0 for success, 1 for failure
    local sorted_completions=($(printf '%s\n' "${COMPREPLY[@]}" | sort))
    local sorted_expected=($(printf '%s\n' "${expected_completions[@]}" | sort))

    # Check for missing expected completions
    for expected in "${sorted_expected[@]}"; do
        if [[ ! " ${sorted_completions[*]} " =~ " $expected " ]]; then
            test_failed=1
            break
        fi
    done

    # Check for unexpected completions
    for completion in "${sorted_completions[@]}"; do
        if [[ ! " ${sorted_expected[*]} " =~ " $completion " ]]; then
            test_failed=1
            break
        fi
    done

    # Store the result before changing directory
    local test_output
    if [ "$test_failed" -eq 0 ]; then
        test_output="${GREEN}✅ $cmdline|${sorted_expected[@]}${NC}"
    else
        test_output="$debug_info
Testing completion for: '$cmdline'
Expected completions: ${sorted_expected[*]}
Actual completions: ${sorted_completions[*]}"
        
        for expected in "${sorted_expected[@]}"; do
            if [[ ! " ${sorted_completions[*]} " =~ " $expected " ]]; then
                test_output+=$'\n'"${RED}❌ Missing expected completion: $expected${NC}"
            fi
        done

        for completion in "${sorted_completions[@]}"; do
            if [[ ! " ${sorted_expected[*]} " =~ " $completion " ]]; then
                test_output+=$'\n'"${RED}❌ Unexpected completion: $completion${NC}"
            fi
        done
        
        test_output+=$'\n'"${RED}❌ Test failed.${NC}"
    fi

    # Change back to original directory
    cd "$original_dir"

    # Print the stored output
    echo -e "$test_output"

    return $test_failed
}

# Function to run a single test case
run_test_case() {
    local case_dir="$1"
    local test_file="$case_dir/tests.txt"
    local total_tests=0
    local passed_tests=0
    local case_name=$(basename "$case_dir")
    
    while IFS='|' read -r command_line expected_completions || [ -n "$command_line" ]; do
        # Skip empty lines and comments
        [[ -z "$command_line" || "$command_line" =~ ^[[:space:]]*# ]] && continue

        # Convert expected completions string to array
        IFS=' ' read -r -a completion_array <<< "$expected_completions"

        # Run the test
        if simulate_completion "$case_dir" "$command_line" "${completion_array[@]}"; then
            ((passed_tests++))
        fi
        ((total_tests++))
    done < "$test_file"

    echo "Results for $case_name:"
    echo "Passed: $passed_tests/$total_tests tests"
    echo "----------------------------------------"
    
    # Return 0 if all tests passed, 1 otherwise
    [ "$passed_tests" -eq "$total_tests" ]
}

# Export functions so they can be used by other scripts
export -f simulate_completion
export -f run_test_case
