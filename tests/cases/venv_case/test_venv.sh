#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_info() { echo -e "${NC}[LOG]: $1${NC}"; }

# Function to clean up test environment
cleanup() {
    log_info "Cleaning up test environment..."
    if [ -d "test_venv" ]; then
        rm -rf test_venv
    fi
    if [ -d "empty_venv" ]; then
        rm -rf empty_venv
    fi
    if [ -d "multi_cli_venv" ]; then
        rm -rf multi_cli_venv
    fi
}

# Function to create a mock CLI script
create_mock_cli() {
    local venv_path="$1"
    local script_name="$2"
    local bin_dir
    
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        bin_dir="Scripts"
    else
        bin_dir="bin"
    fi
    
    cat > "$venv_path/$bin_dir/$script_name" << EOF
#!/usr/bin/env python
import argparse

def main():
    parser = argparse.ArgumentParser(description='Mock CLI tool')
    parser.add_argument('--option1', help='First option')
    parser.add_argument('--option2', help='Second option')
    args = parser.parse_args()

if __name__ == '__main__':
    main()
EOF
    chmod +x "$venv_path/$bin_dir/$script_name"
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

    # Source the completion script early to test registration functions
    source "$COMPLETION_SCRIPT"

    #
    # Test Group 1: Basic Virtual Environment Setup
    #
    log_info "Test Group 1: Basic Virtual Environment Setup"

    log_info "Test 1.1: Creating virtual environment"
    python3 -m venv test_venv
    if [ $? -eq 0 ]; then
        ((passed_count++))
        log_success "Created virtual environment successfully"
    else
        log_error "Failed to create virtual environment"
    fi
    ((test_count++))

    log_info "Test 1.2: Creating empty virtual environment for negative testing"
    python3 -m venv empty_venv
    if [ $? -eq 0 ]; then
        ((passed_count++))
        log_success "Created empty virtual environment successfully"
    else
        log_error "Failed to create empty virtual environment"
    fi
    ((test_count++))

    #
    # Test Group 2: Package Installation and CLI Detection
    #
    log_info "Test Group 2: Package Installation and CLI Detection"

    log_info "Test 2.1: Installing multiple CLI packages"
    source test_venv/bin/activate
    pip install tqdm rich click typer >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        ((passed_count++))
        log_success "Installed CLI packages successfully"
    else
        log_error "Failed to install CLI packages"
    fi
    ((test_count++))

    #
    # Test Group 3: Command Registration Functions
    #
    log_info "Test Group 3: Command Registration Functions"

    log_info "Test 3.1: Testing register_python_command function"
    register_python_command "test_command"
    if list_registered_commands | grep -q "test_command"; then
        ((passed_count++))
        log_success "Successfully registered test command"
    else
        log_error "Failed to register test command"
    fi
    ((test_count++))

    log_info "Test 3.2: Testing duplicate command registration"
    register_python_command "test_command"
    if [ $(list_registered_commands | grep -c "test_command") -eq 1 ]; then
        ((passed_count++))
        log_success "Successfully prevented duplicate command registration"
    else
        log_error "Failed to prevent duplicate command registration"
    fi
    ((test_count++))

    #
    # Test Group 4: Virtual Environment Detection
    #
    log_info "Test Group 4: Virtual Environment Detection"

    log_info "Test 4.1: Testing detect_venv_commands with valid venv"
    detect_venv_commands "$(pwd)/test_venv" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        ((passed_count++))
        log_success "Successfully detected commands in valid venv"
    else
        log_error "Failed to detect commands in valid venv"
    fi
    ((test_count++))

    log_info "Test 4.2: Testing detect_venv_commands with empty venv"
    detect_venv_commands "$(pwd)/empty_venv" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        ((passed_count++))
        log_success "Successfully handled empty venv"
    else
        log_error "Failed to handle empty venv"
    fi
    ((test_count++))

    log_info "Test 4.3: Testing detect_venv_commands with invalid path"
    if ! detect_venv_commands "/nonexistent/path" >/dev/null 2>&1; then
        ((passed_count++))
        log_success "Successfully handled invalid venv path"
    else
        log_error "Failed to handle invalid venv path"
    fi
    ((test_count++))

    #
    # Test Group 5: Command Registration Verification
    #
    log_info "Test Group 5: Command Registration Verification"

    log_info "Test 5.1: Verifying CLI tools registration"
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

    #
    # Test Group 6: Custom CLI Scripts
    #
    log_info "Test Group 6: Custom CLI Scripts"

    log_info "Test 6.1: Testing custom CLI script detection"
    create_mock_cli "$(pwd)/test_venv" "mock_cli"
    detect_venv_commands "$(pwd)/test_venv" >/dev/null 2>&1
    if list_registered_commands | grep -q "mock_cli"; then
        ((passed_count++))
        log_success "Successfully detected and registered custom CLI script"
    else
        log_error "Failed to detect custom CLI script"
    fi
    ((test_count++))

    #
    # Test Group 7: Completion Binding
    #
    log_info "Test Group 7: Completion Binding"

    log_info "Test 7.1: Testing completion binding for registered commands"
    bind_completions
    completion_errors=0
    
    # Get registered commands, skipping the header line
    while IFS= read -r cmd; do
        # Skip empty lines and the header line
        if [[ -z "$cmd" || "$cmd" == "Currently registered commands for argument autocompletion:" ]]; then
            continue
        fi
        
        if ! complete -p "$cmd" 2>/dev/null | grep -q "_python_script_autocomplete"; then
            ((completion_errors++))
            log_error "Completion not properly bound for: $cmd"
        else
            log_success "Completion properly bound for: $cmd"
        fi
    done < <(list_registered_commands)
    
    if [ $completion_errors -eq 0 ]; then
        ((passed_count++))
        log_success "All commands properly bound for completion"
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
