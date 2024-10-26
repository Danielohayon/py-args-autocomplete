# File: tests/cases/venv_case/test_venv.sh
#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

# Function to clean up test environment
cleanup() {
    log_info "Cleaning up test environment..."
    if [ -d "test_venv" ]; then
        rm -rf test_venv
    fi
}

run_venv_tests() {
    local test_count=0
    local passed_count=0
    
    # Get the project root from environment variable
    local PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)}"
    local COMPLETION_SCRIPT="$PROJECT_ROOT/src/python_argparse_complete.sh"

    # Verify completion script exists
    if [ ! -f "$COMPLETION_SCRIPT" ]; then
        log_error "Completion script not found at: $COMPLETION_SCRIPT"
        return 1
    fi

    # Create virtual environment
    log_info "Test 1: Creating virtual environment"
    python3 -m venv test_venv
    if [ $? -eq 0 ]; then
        ((passed_count++))
        log_success "Created virtual environment successfully"
    else
        log_error "Failed to create virtual environment"
    fi
    ((test_count++))

    # Activate virtual environment and install tqdm
    log_info "Test 2: Installing test package (tqdm)"
    source test_venv/bin/activate
    pip install tqdm >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        ((passed_count++))
        log_success "Installed tqdm successfully"
    else
        log_error "Failed to install tqdm"
    fi
    ((test_count++))

    # Source the completion script
    log_info "Test 3: Loading completion script"
    source "$COMPLETION_SCRIPT"
    if [ $? -eq 0 ]; then
        ((passed_count++))
        log_success "Loaded completion script successfully"
    else
        log_error "Failed to load completion script"
    fi
    ((test_count++))

    # Test detect_venv_commands
    log_info "Test 4: Detecting venv commands"
    detect_venv_commands "$(pwd)/test_venv" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        ((passed_count++))
        log_success "Detected venv commands successfully"
    else
        log_error "Failed to detect venv commands"
    fi
    ((test_count++))

    # Test registered commands
    log_info "Test 5: Verifying registered commands"
    commands_output=$(list_registered_commands)
    expected_commands=("python" "python3" "pip" "tqdm")
    all_found=true
    for cmd in "${expected_commands[@]}"; do
        if ! echo "$commands_output" | grep -q "^$cmd$"; then
            all_found=false
            log_error "Missing expected command: $cmd"
        fi
    done
    if [ "$all_found" = true ]; then
        ((passed_count++))
        log_success "All expected commands were registered"
    fi
    ((test_count++))

    # Cleanup
    deactivate
    cleanup

    # Return results
    echo "RESULTS: $passed_count/$test_count"
    [ "$passed_count" -eq "$test_count" ]
}

# If script is run directly (not sourced), execute tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_venv_tests
fi
