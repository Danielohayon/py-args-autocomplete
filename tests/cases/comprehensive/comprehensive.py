import argparse

def main():
    parser = argparse.ArgumentParser(description='A comprehensive test script for argument parsing.')
    
    # Basic arguments with different types
    parser.add_argument('--string', type=str, help='''This option has a very long help message intended to test the parsing capabilities
    when dealing with long descriptions. The help message goes on and on, talking about various aspects of the option,
    when dealing with long descriptions. The help message goes on and on, talking about various aspects of the option,
    when dealing with long descriptions. The help message goes on and on, talking about various aspects of the option,
    its usage, examples, edge cases, and any other relevant information that might be useful for the user to know.
    its usage, examples, edge cases, and any other relevant information that might be useful for the user to know.
    its usage, examples, edge cases, and any other relevant information that might be useful for the user to know.
    It should be properly parsed and displayed without causing any issues.''')
    parser.add_argument('--integer', type=int, help='Integer argument')
    parser.add_argument('--float', type=float, help='Float argument')
    
    # Choices with different types
    parser.add_argument('--color', choices=['red', 'blue', 'green'], help='Color choice')
    parser.add_argument('--level', type=int, choices=[1, 2, 3], help='Level choice')
    
    # Store actions
    parser.add_argument('--verbose', action='store_true', help='Flag argument')
    parser.add_argument('--quiet', action='store_false', help='Negative flag argument')
    parser.add_argument('--mode', action='store_const', const='special', help='Constant store argument')
    
    # Count action
    parser.add_argument('-v', '--verbosity', action='count', help='Verbosity level (-v, -vv, -vvv)')
    
    # Multiple values
    parser.add_argument('--files', nargs='+', help='One or more files')
    parser.add_argument('--optional-files', nargs='*', help='Zero or more files')
    parser.add_argument('--exact-files', nargs=2, help='Exactly two files')
    parser.add_argument('--optional-arg', nargs='?', const='default', help='Optional argument with default')
    
    # Required argument
    parser.add_argument('--required', required=True, help='Required argument')
    
    args = parser.parse_args()

if __name__ == "__main__":
    main()
