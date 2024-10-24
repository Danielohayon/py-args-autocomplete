
# py-args-autocomplete

`py-args-autocomplete` is a tool that provides autocompletion for arguments of any Python script. Unlike other solutions, this tool doesn't require you to modify your Python code or install additional Python packages. It works seamlessly by parsing your script's `--help` output, making it universally compatible with scripts using any argument parsing library.


# Roadmap
* Add support for dual option arguments, such as cases where `-c` and `--config` are both the same argument so if one has been used then don't suggest the other again.
* Add support for positional arguments and subparsers
* Add zsh support 
* Add support for libraries that are initiated without the python keyword (for example vllm, lm_eval, ect)
