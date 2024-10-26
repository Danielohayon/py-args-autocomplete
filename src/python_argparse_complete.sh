#!/bin/bash

_python_script_autocomplete() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # Get the command (first word)
    local command="${words[0]}"
    
    # Check if this is a registered command
    local is_registered=false
    for cmd in "${REGISTERED_COMMANDS[@]}"; do
        if [[ "$command" == "$cmd" ]]; then
            is_registered=true
            break
        fi
    done

    if [ "$is_registered" != "true" ]; then
        COMPREPLY=()
        return 124
    fi

    # Determine the Python interpreter (python or python3)
    local python_interpreter
    if command -v python3 &>/dev/null; then
        python_interpreter='python3'
    elif command -v python &>/dev/null; then
        python_interpreter='python'
    else
        # No Python interpreter found
        COMPREPLY=()
        return 124
    fi

    # For python/python3 commands, we need to look for .py files
    local is_python_interpreter=false
    local script_index=1
    if [[ "$command" == "python" || "$command" == "python3" ]]; then
        is_python_interpreter=true
        # Check for .py file
        local is_python_script=false
        for ((i=1; i<${#words[@]}; i++)); do
            if [[ "${words[i]}" == *.py ]]; then
                is_python_script=true
                script_index=$i
                break
            fi
        done

        # If not in a Python script context, use default completion
        if [ "$is_python_script" != "true" ]; then
            COMPREPLY=()
            return 124
        fi
    fi

    # Get the script or command to execute
    local script
    if [ "$is_python_interpreter" = true ]; then
        script="${words[script_index]}"
        # Check if the script exists and is readable
        if [[ ! -f "$script" || ! -r "$script" ]]; then
            COMPREPLY=()
            return 124
        fi
    else
        script="$command"
    fi

    # If we're still completing the script name or earlier parts, use default completion
    if [ "$is_python_interpreter" = true ] && [[ $cword -le $script_index ]]; then
        COMPREPLY=()
        return 124
    fi

    # Get help output based on command type
    local help_output
    if [ "$is_python_interpreter" = true ]; then
        help_output=$("$python_interpreter" "$script" --help 2>/dev/null)
    else
        help_output=$("$command" --help 2>/dev/null)
    fi

    # Extract the options section from the help output
    options_lines=$(echo "$help_output" | sed -n '/^options:/I,/^[[:space:]]*$/p')

    # Initialize associative arrays
    declare -A arg_choices
    declare -A arg_aliases

    # Process each line in the options section
    while IFS= read -r line; do
        # [Rest of the existing option processing code remains the same]
        # Remove leading and trailing whitespace
        line=$(echo "$line" | sed 's/^[ \t]*//;s/[ \t]*$//')
        # Skip empty lines or lines that don't start with '-'
        [[ -z "$line" || "${line:0:1}" != "-" ]] && continue

        # Split the line into option part and description based on two or more spaces
        option_part=$(echo "$line" | awk -F '[[:space:]]{2,}' '{print $1}')
        # Remove leading and trailing whitespace from option_part
        option_part=$(echo "$option_part" | sed 's/^[ \t]*//;s/[ \t]*$//')

        # Initialize rest as option_part
        rest="$option_part"
        local first_option=""
        # Loop to extract options and store aliases
        while [[ -n "$rest" ]]; do
            # Remove leading commas and spaces
            rest="${rest#,}"
            rest="${rest# }"
            rest="${rest#	}"

            if [[ "$rest" =~ ^(-{1,2}[^\ ]+)(\ \{[^\}]+\})?(.*)$ ]]; then
                option="${BASH_REMATCH[1]}"
                choices="${BASH_REMATCH[2]}"
                rest="${BASH_REMATCH[3]}"

                # Remove leading spaces from rest
                rest="${rest# }"
                rest="${rest#	}"

                # Store alias relationships
                if [[ -z "$first_option" ]]; then
                    first_option="$option"
                else
                    arg_aliases["$option"]="$first_option"
                    arg_aliases["$first_option"]="$option"
                fi

                # Remove choices braces if present
                if [[ -n "$choices" ]]; then
                    choices="${choices# \{}"
                    choices="${choices%\}}"
                    IFS=',' read -ra choices_array <<< "$choices"
                    # Trim whitespace from choices
                    for i in "${!choices_array[@]}"; do
                        choices_array[$i]=$(echo "${choices_array[$i]}" | xargs)
                    done
                else
                    choices_array=()
                fi

                # Store option and choices in the associative array
                arg_choices["$option"]="${choices_array[*]}"
            else
                # No match, break the loop
                break
            fi
        done
    done <<< "$options_lines"

    # [Rest of the existing completion logic remains the same]
    # Extract all possible arguments
    local args=$(echo "$help_output" | \
        grep -oE "(--[a-zA-Z0-9_-]+|-[a-zA-Z0-9_-])" | \
        sort -u)

    # If the command failed or no arguments were found, fallback to filename completion
    if [[ -z "$args" ]]; then
        COMPREPLY=()
        return 124
    fi

    # If previous word is an argument that accepts choices, suggest choices
    if [[ -n "${arg_choices[$prev]}" ]]; then
        local choices="${arg_choices[$prev]}"
        COMPREPLY=($(compgen -W "$choices" -- "$cur"))
        return
    fi

    # Check if we're explicitly looking for arguments
    if [[ "$cur" == -* ]] || [[ "$cur" == *- ]]; then
        # Initialize array for used arguments and their aliases
        local used_args=("--help" "-h")
        local start_index
        if [ "$is_python_interpreter" = true ]; then
            start_index=$script_index
        else
            start_index=1
        fi
        
        for ((i=start_index+1; i<${#words[@]}; i++)); do
            if [[ "${words[i]}" == -* ]]; then
                used_args+=("${words[i]}")
                # If this argument has an alias, add it to used_args
                if [[ -n "${arg_aliases[${words[i]}]}" ]]; then
                    used_args+=("${arg_aliases[${words[i]}]}")
                fi
            fi
        done

        # Remove used arguments from args
        for used_arg in "${used_args[@]}"; do
            args=$(echo "$args" | grep -v "^${used_arg}$")
        done

        # Suggest arguments
        COMPREPLY=($(compgen -W "$args" -- "$cur"))
        return
    fi

    # Default to normal bash completion for everything else
    COMPREPLY=()
    return 124
}
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

    # Check if the venv path exists
    if [ ! -d "$venv_path" ]; then
        echo "Virtual environment directory not found: $venv_path"
        return 1
    fi

    # Check if the bin directory exists
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

        # Check if file is a script (has shebang with python)
        if [ -f "$file" ] && [ -x "$file" ]; then
            # First try to check shebang
            if head -n 1 "$file" | grep -q "python"; then
                register_python_command "$(basename "$file")"
                ((count++))
            # If no python in shebang and file command exists, try that
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
    # Check if command already exists in REGISTERED_COMMANDS
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

# Rest of the _python_script_autocomplete function remains the same as in the previous version
# [Previous _python_script_autocomplete function code goes here]

# Initial binding of completions
bind_completions

if [ "$1" == "--DEBUG" ]; then
    # provide a help message
    echo "Python argument autocompletion loaded!"
    echo "Available commands:"
    echo "  detect_venv_commands [venv_path] - Detect and register Python entry points from a virtualenv"
    echo "  register_python_command <command> - Manually register a command for autocompletion"
    echo "  list_registered_commands - List all registered commands"
fi

