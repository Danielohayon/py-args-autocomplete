
# py-args-autocomplete

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

`py-args-autocomplete` is a tool that provides autocompletion for arguments of any Python script. Unlike other solutions, this tool doesn't require you to modify your Python code or install additional Python packages. It works seamlessly by parsing your script's `--help` output, making it universally compatible with scripts using any argument parsing library.

## 🚀 Features

- **Intelligent Autocompletion:** Automatically suggests arguments based on your Python script's `--help` output.
- **Choice Suggestions:** If an argument accepts specific choices, those are suggested during completion.
- **Supports Short and Long Options:** Completes both short (`-h`) and long (`--help`) options.
- **Fallback to Default Completion:** If not in a Python script context, it defaults to Bash's standard completion.

## 📥 Installation

1. Clone the repo into a folder of your choosing `git clone https://github.com/Danielohayon/py-args-autocomplete.git`
2. Add this line to your `~/.bashrc` file `source /path/to/cloned/repo/src/python_argparse_complete.sh`
3. Reload Your Shell `source ~/.bashrc`



## 🛠 Usage

Simply run your Python script as you normally would, and press `Tab` to trigger autocompletion:

```bash
python your_script.py --[Press Tab]
```

The script will suggest available arguments and options based on your script's `--help` output.

### Example

Assuming `your_script.py` has the following options:

```bash
options:
  -h, --help            show this help message and exit
  --mode {auto,manual}  Choose the mode of operation.
  --verbose             Enable verbose output.
```

Typing:

```bash
python your_script.py --[Press Tab]
```

Will suggest:

```bash
--help   --mode   --verbose
```

If you type:

```bash
python your_script.py --mode [Press Tab]
```

It will suggest the choices:

```bash
auto   manual
```

## 🧪 Testing

To test the autocompletion run:

   ```bash
   ./tests/master_test.sh
   ```

## 🤝 Contributing

Contributions are welcome! Take a look at the repo's [Project page](https://github.com/users/Danielohayon/projects/1) to see open feature requests or requests some of your own ideas.

## 📄 License

This project is licensed under the [MIT License](LICENSE).

## 📫 Contact

For questions or suggestions, feel free to open an issue or reach out via email at [your.email@example.com](mailto:your.email@example.com).

## ⭐️ Support

If you find this project helpful, please give it a star on GitHub!
