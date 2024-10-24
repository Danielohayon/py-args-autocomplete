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

    # Get the Python script path
    local script_name="$(basename "$case_dir").py"
    local script_path="$case_dir/$script_name"

    # Build the modified command line by replacing the script name with the full path
    local script_base_name="$(basename "$script_path")"
    local modified_cmdline="${cmdline/$script_base_name/$script_path}"

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

    # Call the autocompletion function
    _python_script_autocomplete

    # Capture the completion suggestions
    local completions=("${COMPREPLY[@]}")

    # Prepare debug info (but don't print it yet)
    local debug_info="Debug info:
Original command line: $cmdline
Modified command line: $modified_cmdline
COMP_WORDS (${#COMP_WORDS[@]}): ${COMP_WORDS[*]}
COMP_CWORD: $COMP_CWORD
cur: '$cur'
prev: '$prev'
COMP_LINE: $COMP_LINE
COMP_POINT: $COMP_POINT
Expected completions: ${expected_completions[*]}
Actual completions: ${completions[*]}"

    # Verify the completions
    local test_failed=false

    # Check for missing expected completions
    for expected in "${expected_completions[@]}"; do
        if [[ ! " ${completions[*]} " =~ " $expected " ]]; then
            test_failed=true
            break
        fi
    done

    # Check for unexpected completions
    for completion in "${completions[@]}"; do
        if [[ ! " ${expected_completions[*]} " =~ " $completion " ]]; then
            test_failed=true
            break
        fi
    done

    if [ "$test_failed" = false ]; then
        # For successful tests, just print a green checkmark and the command
        echo -e "${GREEN}✅ $cmdline | ${expected_completions[@]}${NC}"
        return 0
    else
        # For failed tests, print all debug info
        echo "$debug_info"
        echo "Test failed for: '$cmdline'"
        
        # Print missing completions
        for expected in "${expected_completions[@]}"; do
            if [[ ! " ${completions[*]} " =~ " $expected " ]]; then
                echo -e "${RED}❌ Missing expected completion: $expected${NC}"
            fi
        done

        # Print unexpected completions
        for completion in "${completions[@]}"; do
            if [[ ! " ${expected_completions[*]} " =~ " $completion " ]]; then
                echo -e "${RED}❌ Unexpected completion: $completion${NC}"
            fi
        done
        
        echo -e "${RED}❌ Test failed.${NC}"
        return 1
    fi
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
        else
            echo "----------------------------------------"
        fi
        ((total_tests++))
    done < "$test_file"

    echo "Results for $case_name:"
    echo "Passed: $passed_tests/$total_tests tests"
    echo "----------------------------------------"
    return $((total_tests - passed_tests))
}

# Export functions so they can be used by other scripts
export -f simulate_completion
export -f run_test_case
