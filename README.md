# py-args-autocomplete - It Just Works
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Why?
Ever found yourself typing `python script.py --output` and freezing... *"Was it --output_path or --output_base_path? Or maybe just --output?"* 😅

We've all been there: hastily hitting Ctrl+C, running `python script.py --help`, only to realize your carefully crafted command is now lost to the bash history void. And of course, the moment you see the help output, you remember you also needed to set `--num-workers`.

Say goodbye to that workflow! With `py-args-autocomplete`, just hit Tab and watch the magic happen. 


## 🚀 Features

`py-args-autocomplete` is a tool that provides autocompletion for arguments of any Python script. Unlike other solutions, this tool doesn't require you to modify your Python code or install additional Python packages. It works seamlessly by parsing your script's `--help` output, making it universally compatible with scripts using any argument parsing library.

- **Zero Configuration:** Works out of the box with any Python script that supports `--help`, regardless of the argument parsing library used.
- **Choice Suggestions:** If an argument accepts specific choices (e.g., `--format {json,yaml,text}`), those specific options are automatically suggested.
- **Context-Aware Completion:**
  - Triggers when typing `--` or `-` (or after typing an argument that has set choices).
  - Otherwise fallbacks to the defualt bash autocompletion for argument values (paths, files, etc.)
  - Smart filtering to hide already used arguments
- **Supports Short and Long Options:** Completes both short (`-c`) and long (`--config`) options, including handling of aliases (and if one was used knows not to suggest the other).

## 📥 Installation

### Quick Install
1. Clone the repository:
   ```bash
   git clone https://github.com/Danielohayon/py-args-autocomplete.git
   ```
2. Add this line to your `~/.bashrc` file:
   ```bash
   source /path/to/cloned/repo/src/python_argparse_complete.sh
   ```
3. Reload your shell:
   ```bash
   source ~/.bashrc
    ```

## 🛠 Usage

### Just Works
Simply type your Python script name as you normally would, add `-` to trigger the autocompletion and press `Tab` to autocomplete:
```bash
python your_script.py --[Press Tab]
```
### Example

Consider a script with these options:
```python
import argparse

def main():
    parser = argparse.ArgumentParser(description='A sample script with arguments.')
    parser.add_argument('--input', type=str, choices=["in1", "in2"], help='Input file name')
    parser.add_argument('--output', type=str, help='Output file name')
    parser.add_argument('--verbose', action='store_true', help='Increase output verbosity')
    parser.add_argument('--level', type=int, choices=[1, 2, 3], help='Level of operation')
    parser.add_argument('-c', '--config', choices=["in1", "in2", "in3"], help='Path to configuration file')
    args = parser.parse_args()
    print(f"Arguments received: {args}")

if __name__ == "__main__":
    main()
```


The autocomplete behavior will be:
```bash
# 1. Complete all available arguments
$ python sample_script.py --[Tab]
--input --output --verbose --level --config

# 2. Complete predefined choices
$ python sample_script.py --input [Tab]
in1 in2

$ python sample_script.py --level [Tab]
1 2 3

# 3. Show remaining unused arguments 
$ python sample_script.py --input in1 --verbose --level 1 --[Tab]
--config --output  

# 4. Support both long and short options with choices
$ python sample_script.py --config [Tab]
in1 in2 in3

$ python sample_script.py -c [Tab]
in1 in2 in3

$ python sample_script.py --con[Tab]
--config

# 5. -c has already been used so no need to show --config
$ python sample_script.py -c in1 --[Tab]
--input --output --verbose --level 
```

## 🧪 Testing

### Running Tests
Execute the test suite:
```bash
./tests/master_test.sh
```

### Test Coverage
The test suite covers:
- Basic argument completion
- Filtering to hide already used arguments
- Choice completion
- File path completion
- Edge cases and error handling

## 🔍 Troubleshooting

### Common Issues
**Completion not working:**
- Ensure the script is properly sourced in `~/.bashrc`
- Check Python script has proper `--help` output by running `python your_script_name.py --help` which should be automatically generated for every python script using `argparse`

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. Check out the [Project page](https://github.com/users/Danielohayon/projects/1) for open features or suggest your own ideas.
2. Fork the repository
3. Create a feature branch
4. Write tests for your feature
5. Before submitting PR, run the test suite as mentioned in [🧪 Testing](#-testing) to make sure no other features have been broken.
6. Submit a pull request

## 📄 License

This project is licensed under the [MIT License](LICENSE).

## 📫 Contact

- **Email:** [ohayon.daniel4@gmail.com](mailto:ohayon.daniel4@gmail.com)

## ⭐️ Support

If you find this project helpful:
- Give it a star on GitHub
- Share it with others
- Consider contributing



