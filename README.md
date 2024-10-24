
# py-args-autocomplete

`py-args-autocomplete` is a tool that provides autocompletion for arguments of any Python script. Unlike other solutions, this tool doesn't require you to modify your Python code or install additional Python packages. It works seamlessly by parsing your script's `--help` output, making it universally compatible with scripts using any argument parsing library.


## Roadmap
* [x] Add support for default bash autocomplete fallback when argument suggestion is irrelevant (such as when still typing the script name)
* [x] Add support for suggesting options for an argument after it has been typed. For example after typing `python script.py --type <tab>` it would suggest the listed options for the type argument
* [x] Unify testing code
* [ ] Beif up testing to be more extensive and robust with long argument names and help messages
* [x] Add support for dual option arguments, such as cases where `-c` and `--config` are both the same argument so if one has been used then don't suggest the other again.
* [ ] Beif up README page with examples and some documentation
* [ ] Add support for libraries that are initiated without the Python keyword (for example film, lm_eval, etc.)
* [ ] Add support for positional arguments and sub-parsers
* [ ] Add integration with popular CLI frameworks (click, typer)
* [ ] Add zsh support 
* [ ] Package as a package for ease of installation with `apt` and `brew` for example.
* [ ] Add performance benchmarks
* [ ] Add extensive documentation
* [ ] Add caching to optimization


## tbd
* [ ] Add support for other languages (js)?
* [ ] fuzzy matching?
