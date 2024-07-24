#!/bin/bash

_python_script_autocomplete() {
    local cur prev words cword
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

    # If not in a Python script context, exit without doing anything
    if ! $is_python_script; then
        return
    fi

    # Get the script name
    local script="${words[script_index]}"

    # Check if the script exists and is readable
    if [[ ! -f "$script" || ! -r "$script" ]]; then
        return
    fi

    # If we're still completing the script name or earlier parts, exit without doing anything
    if [[ $cword -le $script_index ]]; then
        return
    fi

    # If the current word starts with '-', complete with script arguments
    if [[ $cur == -* ]]; then
        # Extract arguments from the script
        local args=$(grep -oP "(?<=add_argument\().*?(?=\))" "$script" | grep -oP "('--\w+)|('-\w')" | tr -d "'")
        COMPREPLY=($(compgen -W "$args" -- "$cur"))
    fi
    # We're not handling non-dash arguments anymore, letting the default completion take over
}

complete -F _python_script_autocomplete python


# #!/bin/bash
#
# _python_script_autocomplete() {
#     local cur prev words cword
#     cur="${COMP_WORDS[COMP_CWORD]}"
#     prev="${COMP_WORDS[COMP_CWORD-1]}"
#     words=("${COMP_WORDS[@]}")
#     cword=$COMP_CWORD
#
#     # Check if we're in a valid Python script execution context
#     local is_python_script=false
#     local script_index=-1
#     for ((i=1; i<${#words[@]}; i++)); do
#         if [[ "${words[i]}" == *.py ]]; then
#             is_python_script=true
#             script_index=$i
#             break
#         fi
#     done
#
#     # If not in a Python script context, use default completion
#     if ! $is_python_script; then
#         _filedir
#         return
#     fi
#
#     # Get the script name
#     local script="${words[script_index]}"
#
#     # Check if the script exists and is readable
#     if [[ ! -f "$script" || ! -r "$script" ]]; then
#         _filedir
#         return
#     fi
#
#     # If we're still completing the script name or earlier parts, use default completion
#     if [[ $cword -le $script_index ]]; then
#         _filedir
#         return
#     fi
#
#     # If the current word starts with '-', complete with script arguments
#     if [[ $cur == -* ]]; then
#         # Extract arguments from the script
#         local args=$(grep -oP "(?<=add_argument\().*?(?=\))" "$script" | grep -oP "('--\w+)|('-\w')" | tr -d "'")
#         COMPREPLY=($(compgen -W "$args" -- "$cur"))
#     else
#         # For non-dash arguments, use default completion
#         _filedir
#     fi
# }
#
# complete -F _python_script_autocomplete python
