def sum_second_integers(filename):
    total = 0
    with open(filename, 'r') as file:
        for line in file:
            parts = line.split(': ')
            if len(parts) == 2:
                try:
                    number = int(parts[1])
                    total += number
                except ValueError:
                    # Handle the case where the conversion to int fails
                    print(f"Could not convert to integer: {parts[1]}")
    return total

# Example usage
total = sum_second_integers("ipis.txt")
print(f"Total: {total}")