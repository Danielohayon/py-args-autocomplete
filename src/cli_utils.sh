#!/bin/bash

# Array to store registered commands
declare -a REGISTERED_COMMANDS=("python" "python3")

# Function to detect Python entry points in a virtual environment
detect_venv_commands() {
    local venv_path="$1"
    
    # If no path provided, try to detect active venv
    if [ -z "$venv_path" ]; then
        if [ -n "$VIRTUAL_ENV" ]; then
            venv_path="$VIRTUAL_ENV"
        else
            echo "No virtual environment path provided and no active virtual environment detected."
            return 1
        fi
    fi

    # Determine the bin directory based on OS
    local bin_dir
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        bin_dir="Scripts"
    else
        bin_dir="bin"
    fi

    # Validate directories
    if [ ! -d "$venv_path" ]; then
        echo "Virtual environment directory not found: $venv_path"
        return 1
    fi

    if [ ! -d "$venv_path/$bin_dir" ]; then
        echo "Bin directory not found in virtual environment: $venv_path/$bin_dir"
        return 1
    fi

    local count=0
    echo "Scanning for Python entry points in: $venv_path/$bin_dir"
    
    # Check if file command exists
    local has_file_command=false
    if command -v file >/dev/null 2>&1; then
        has_file_command=true
    fi
    
    # Find all executable files in the bin directory
    while IFS= read -r -d '' file; do
        # Skip python, python3, pip, etc.
        local basename=$(basename "$file")
        if [[ "$basename" =~ ^(python|python3|activate|easy_install|wheel)$ ]]; then
            continue
        fi

        # Check if file is a Python script
        if [ -f "$file" ] && [ -x "$file" ]; then
            if head -n 1 "$file" | grep -q "python"; then
                register_python_command "$(basename "$file")"
                ((count++))
            elif [ "$has_file_command" = true ] && file "$file" | grep -q "Python script"; then
                register_python_command "$(basename "$file")"
                ((count++))
            fi
        fi
    done < <(find "$venv_path/$bin_dir" -type f -executable -print0)

    echo "Registered $count new Python entry points for autocompletion"
    
    # Rebind completion for all commands
    bind_completions
}

# Function to register a new command for autocompletion
register_python_command() {
    local command="$1"
    # Check if command already exists
    for cmd in "${REGISTERED_COMMANDS[@]}"; do
        if [[ "$cmd" == "$command" ]]; then
            return
        fi
    done
    REGISTERED_COMMANDS+=("$command")
    echo "Registered new command: $command"
}

# Function to list all registered commands
list_registered_commands() {
    echo "Currently registered commands for argument autocompletion:"
    printf '%s\n' "${REGISTERED_COMMANDS[@]}" | sort
}

# Function to bind completions for all registered commands
bind_completions() {
    for cmd in "${REGISTERED_COMMANDS[@]}"; do
        complete -o default -o bashdefault -F _python_script_autocomplete "$cmd"
    done
}
