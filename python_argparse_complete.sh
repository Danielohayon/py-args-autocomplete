#!/bin/bash

_python_script_autocomplete() {
    if ! declare -F _filedir >/dev/null; then
        _filedir() {
            compgen -f -- "$cur"
        }
    fi

    local cur prev words cword
    _init_completion || return

    # Determine the Python interpreter to use
    local python_interpreter
    if command -v python3 >/dev/null 2>&1; then
        python_interpreter=python3
    elif command -v python >/dev/null 2>&1; then
        python_interpreter=python
    else
        # No Python interpreter found
        return
    fi

    # Check if we're in a valid Python script execution context
    local is_python_script=false
    local script_index=-1
    for ((i=1; i<${#words[@]}; i++)); do
        if [[ "${words[i]}" == *.py ]]; then
            is_python_script=true
            script_index=$i
            break
        fi
    done

    # If not in a Python script context, use default completion
    if [ "$is_python_script" != "true" ]; then
        _filedir
        return
    fi

    # Get the script name
    local script="${words[script_index]}"

    # Check if the script exists and is readable
    if [[ ! -f "$script" || ! -r "$script" ]]; then
        _filedir
        return
    fi

    # If we're still completing the script name or earlier parts, use default completion
    if [[ $cword -le $script_index ]]; then
        _filedir
        return
    fi

    # Extract arguments from the script's --help output
    # Exclude the '--help' argument from the suggestions
    help_output=$($python_interpreter "$script" --help 2>/dev/null)
    local args=$(echo "$help_output" | \
        grep -oE "(--[a-zA-Z0-9_-]+|-[a-zA-Z0-9_-])" | \
        sort -u)

    # Extract the options section from the help output
    options_lines=$(echo "$help_output" | sed -n '/^options:/,/^[[:space:]]*$/p')

    # Initialize an associative array to store arguments and their choices
    declare -A arg_choices

    # Process each line in the options section
    while IFS= read -r line; do
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
        # Loop to extract options
        while [[ -n "$rest" ]]; do
            # Remove leading commas and spaces
            rest="${rest#,}"
            rest="${rest# }"
            rest="${rest#	}"  # Remove leading tabs too

            if [[ "$rest" =~ ^(-{1,2}[^\ ]+)(\ \{[^\}]+\})?(.*)$ ]]; then
                option="${BASH_REMATCH[1]}"
                choices="${BASH_REMATCH[2]}"
                rest="${BASH_REMATCH[3]}"

                # Remove leading spaces from rest
                rest="${rest# }"
                rest="${rest#	}"

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

    # If the command failed or no arguments were found, fallback to default completion
    if [[ -z "$args" ]]; then
        _filedir
        return
    fi


    # If previous word is an argument that accepts choices, suggest choices
    if [[ -n "${arg_choices[$prev]}" ]]; then
        local choices="${arg_choices[$prev]}"
        COMPREPLY=($(compgen -W "$choices" -- "$cur"))
        return
    fi

    # Exclude arguments that have already been used
    local used_args=("--help" "-h")
    for ((i=script_index+1; i<${#words[@]}; i++)); do
        if [[ "${words[i]}" == -* ]]; then
            used_args+=("${words[i]}")
        fi
    done

    # Remove used arguments from args
    for used_arg in "${used_args[@]}"; do
        args=$(echo "$args" | grep -v "^${used_arg}$")
    done
    # Suggest arguments
    COMPREPLY=($(compgen -W "$args" -- "$cur"))
}

complete -F _python_script_autocomplete python
complete -F _python_script_autocomplete python3

