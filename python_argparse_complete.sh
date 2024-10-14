#!/bin/bash

_python_script_autocomplete() {
    if ! declare -F _filedir >/dev/null; then
        _filedir() {
            compgen -f -- "$cur"
        }
    fi

    local cur prev words cword
    _init_completion -n "=" || return

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
    local script_path=$(command -v "$script" || echo "$script")

    # Check if the script exists and is readable
    if [[ ! -f "$script_path" || ! -r "$script_path" ]]; then
        _filedir
        return
    fi

    # If we're still completing the script name or earlier parts, use default completion
    if [[ $cword -le $script_index ]]; then
        _filedir
        return
    fi

    # If the current word starts with '-', complete with script arguments
    if [[ $cur == -* ]]; then
        # Extract arguments from the script's --help output
        local args=$(python3 "$script_path" --help 2>/dev/null | grep -oE "(--[a-zA-Z0-9_-]+)|(-[a-zA-Z0-9_-])")
        COMPREPLY=($(compgen -W "$args" -- "$cur"))
    else
        # For non-dash arguments, use default completion
        _filedir
    fi
}

complete -F _python_script_autocomplete python
complete -F _python_script_autocomplete python3

