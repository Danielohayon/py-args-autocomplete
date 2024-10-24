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
    local cmdline="$1"
    shift
    local expected_completions=("$@")

    # Convert relative paths to absolute paths in the command line
    local modified_cmdline="${cmdline/python sample_scripts/python $PROJECT_ROOT/tests/sample_scripts}"

    # Determine if there's a trailing space
    local trailing_space=0
    [[ "$modified_cmdline" == *" " ]] && trailing_space=1

    # Split the command line into words
    IFS=' ' read -r -a COMP_WORDS <<< "$modified_cmdline"

    # If there's a trailing space, add an empty word
    [ $trailing_space -eq 1 ] && COMP_WORDS+=("")

    # Set COMP_CWORD to the index of the current word
    COMP_CWORD=${#COMP_WORDS[@]}
    ((COMP_CWORD--))

    # Set cur and prev
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev
    [ $COMP_CWORD -ge 1 ] && prev="${COMP_WORDS[COMP_CWORD-1]}" || prev=""

    # Set COMP_LINE and COMP_POINT
    COMP_LINE="$modified_cmdline"
    COMP_POINT=${#COMP_LINE}

    # Initialize COMPREPLY
    COMPREPLY=()

    # Call the autocompletion function
    _python_script_autocomplete

    # Capture the completion suggestions
    local completions=("${COMPREPLY[@]}")

    # Debug output
    echo "Debug info:"
    echo "Modified command line: $modified_cmdline"
    echo "COMP_WORDS: ${COMP_WORDS[*]}"
    echo "COMP_CWORD: $COMP_CWORD"
    echo "cur: '$cur'"
    echo "prev: '$prev'"
    echo "COMP_LINE: $COMP_LINE"
    echo "COMP_POINT: $COMP_POINT"

    # Verify the completions
    local test_failed=false

    echo "Testing completion for: '$cmdline'"
    echo "Expected completions: ${expected_completions[*]}"
    echo "Actual completions: ${completions[*]}"

    # Check for missing expected completions
    for expected in "${expected_completions[@]}"; do
        if [[ ! " ${completions[*]} " =~ " $expected " ]]; then
            echo -e "${RED}❌ Missing expected completion: $expected${NC}"
            test_failed=true
        fi
    done

    # Check for unexpected completions
    for completion in "${completions[@]}"; do
        if [[ ! " ${expected_completions[*]} " =~ " $completion " ]]; then
            echo -e "${RED}❌ Unexpected completion: $completion${NC}"
            test_failed=true
        fi
    done

    if [ "$test_failed" = false ]; then
        echo -e "${GREEN}✅ Test passed.${NC}"
        return 0
    else
        echo -e "${RED}❌ Test failed.${NC}"
        return 1
    fi
}

# Function to run a single test case
run_test_case() {
    local test_file="$1"
    local total_tests=0
    local passed_tests=0

    while IFS='|' read -r command_line expected_completions || [ -n "$command_line" ]; do
        # Skip empty lines and comments
        [[ -z "$command_line" || "$command_line" =~ ^[[:space:]]*# ]] && continue

        # Convert expected completions string to array
        IFS=' ' read -r -a completion_array <<< "$expected_completions"

        # Run the test
        if simulate_completion "$command_line" "${completion_array[@]}"; then
            ((passed_tests++))
        fi
        ((total_tests++))
        echo "----------------------------------------"
    done < "$test_file"

    echo "Results for $test_file:"
    echo "Passed: $passed_tests/$total_tests tests"
    return $((total_tests - passed_tests))
}

# Export functions so they can be used by other scripts
export -f simulate_completion
export -f run_test_case
