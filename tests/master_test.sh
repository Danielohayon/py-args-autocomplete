#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the test runner
source "$SCRIPT_DIR/lib/test_runner.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Initialize counters
total_test_files=0
passed_test_files=0

# Make sure all Python scripts are executable
find "$PROJECT_ROOT/tests/sample_scripts" -name "*.py" -exec chmod +x {} \;

# Function to run all tests in a directory
run_tests_in_dir() {
    local test_dir="$1"
    local test_files=("$test_dir"/*.txt)
    
    echo "Running tests in $test_dir"
    echo "=========================="
    
    for test_file in "${test_files[@]}"; do
        if [ -f "$test_file" ]; then
            ((total_test_files++))
            if run_test_case "$test_file"; then
                ((passed_test_files++))
                echo -e "${GREEN}✅ All tests in $(basename "$test_file") passed${NC}"
            else
                echo -e "${RED}❌ Some tests in $(basename "$test_file") failed${NC}"
            fi
            echo
        fi
    done
}

# Run all test cases
for test_case_dir in "$SCRIPT_DIR/test_cases"/*/ ; do
    if [ -d "$test_case_dir" ]; then
        run_tests_in_dir "$test_case_dir"
    fi
done

# Print final results
echo "Final Results"
echo "============"
echo -e "Passed test files: ${GREEN}$passed_test_files/$total_test_files${NC}"

# Exit with appropriate status code
[ "$passed_test_files" -eq "$total_test_files" ]
