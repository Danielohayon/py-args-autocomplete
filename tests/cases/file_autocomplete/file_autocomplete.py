import argparse

def main():
    parser = argparse.ArgumentParser(description='Test script for file autocompletion')
    parser.add_argument('--input-file', help='Input file path')
    parser.add_argument('--output-file', help='Output file path')
    parser.add_argument('--multiple-files', nargs='+', help='Multiple input files')
    parser.add_argument('--type', choices=['txt', 'json'], help='File type')
    
    args = parser.parse_args()

if __name__ == "__main__":
    main()
