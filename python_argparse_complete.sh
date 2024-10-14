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
    local args=$($python_interpreter "$script" --help 2>/dev/null | \
                 grep -oE "(--[a-zA-Z0-9_-]+|-[a-zA-Z0-9_-])" | \
                 sort -u)

    # If the command failed or no arguments were found, fallback to default completion
    if [[ -z "$args" ]]; then
        _filedir
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

    # Provide completion suggestions
    COMPREPLY=($(compgen -W "$args" -- "$cur"))
}

complete -F _python_script_autocomplete python
complete -F _python_script_autocomplete python3

