#!/bin/bash

_python_script_autocomplete() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

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
        COMPREPLY=()
        return 124  # Use 124 to tell Bash to use default completion
    fi

    # Get the script name
    local script="${words[script_index]}"

    # Check if the script exists and is readable
    if [[ ! -f "$script" || ! -r "$script" ]]; then
        COMPREPLY=()
        return 124
    fi

    # If we're still completing the script name or earlier parts, use default completion
    if [[ $cword -le $script_index ]]; then
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

    # Extract arguments from the script's --help output
    help_output=$($python_interpreter "$script" --help 2>/dev/null)

    # Extract the options section from the help output
    options_lines=$(echo "$help_output" | sed -n '/^options:/I,/^[[:space:]]*$/p')

    # Initialize associative arrays
    declare -A arg_choices
    declare -A arg_aliases  # New array to store argument aliases

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

    # Initialize array for used arguments and their aliases
    local used_args=("--help" "-h")
    for ((i=script_index+1; i<${#words[@]}; i++)); do
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
}

# Bind the autocomplete function to python and python3 commands
complete -o default -o bashdefault -F _python_script_autocomplete python
complete -o default -o bashdefault -F _python_script_autocomplete python3

