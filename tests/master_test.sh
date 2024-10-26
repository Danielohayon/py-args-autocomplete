#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the test runner
source "$SCRIPT_DIR/lib/test_runner.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize counters
total_test_files=0
passed_test_files=0

# Make sure all Python scripts are executable
find "$SCRIPT_DIR/cases" -name "*.py" -exec chmod +x {} \;

# First run all standard test cases
for case_dir in "$SCRIPT_DIR/cases"/*/ ; do
    if [ -d "$case_dir" ] && [ -f "$case_dir/tests.txt" ]; then
        ((total_test_files++))
        case_name=$(basename "$case_dir")
        echo -e "${YELLOW}Running tests for $case_name${NC}"
        echo "=========================="
        
        if run_test_case "$case_dir"; then
            ((passed_test_files++))
            echo -e "${GREEN}✅ All tests in $case_name passed${NC}"
        else
            echo -e "${RED}❌ Some tests in $case_name failed${NC}"
        fi
        echo
    fi
done

# Run the virtual environment test case
venv_test_script="$SCRIPT_DIR/cases/venv_case/test_venv.sh"
if [ -f "$venv_test_script" ]; then
    ((total_test_files++))
    echo -e "${YELLOW}Running virtual environment tests${NC}"
    echo "================================"
    
    # Export PROJECT_ROOT for the venv test script
    export PROJECT_ROOT
    
    if bash "$venv_test_script"; then
        ((passed_test_files++))
        echo -e "${GREEN}✅ Virtual environment tests passed${NC}"
    else
        echo -e "${RED}❌ Virtual environment tests failed${NC}"
    fi
    echo
fi

# Print final results
echo "Final Results"
echo "============"
echo -e "Passed test files: ${GREEN}$passed_test_files/$total_test_files${NC}"

# Exit with appropriate status code
[ "$passed_test_files" -eq "$total_test_files" ]
