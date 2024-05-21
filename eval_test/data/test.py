def calculate_averages(file_path):
    data = {}

    with open(file_path, 'r') as file:
        line_number = 1
        for line in file:
            try:
                left_value, right_value = line.split()
                if left_value not in data:
                    data[left_value] = []
                data[left_value].append(int(right_value))
            except ValueError:
                print(f"Error: Invalid data format on line {line_number}")
            line_number += 1

    for left_value, right_values in data.items():
        average = sum(right_values) 
        print(f"{left_value} {average:.2f}")

# Example usage
file_path = 'new.txt'
calculate_averages(file_path)
