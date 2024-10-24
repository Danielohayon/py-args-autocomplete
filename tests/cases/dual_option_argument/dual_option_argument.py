import argparse

def main():
    parser = argparse.ArgumentParser(description='A sample script with arguments.')
    parser.add_argument('--input', type=str, choices=["in1", "in2"], help='Input file name')
    parser.add_argument('--output', help='Output file name')
    parser.add_argument('--verbose', action='store_true', help='Increase output verbosity')
    parser.add_argument('--level', type=int, choices=[1, 2, 3], help='Level of operation')
    parser.add_argument('-c', '--config', choices=["in1", "in2", "in3"], help='Path to configuration file')

    args = parser.parse_args()
    print(f"Arguments received: {args}")

if __name__ == "__main__":
    main()

