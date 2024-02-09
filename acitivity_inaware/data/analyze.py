# Define the list of phrases to look for
phrases_to_find = ["events (avg/stddev)","Requests/sec", "real", "Set Migration Cost to","Cache-Hot","Cache-Hot 32ms tests"]

# Open and read the text file line by line
with open("acitivity_inaware-411031748.txt", "r") as file:
    for line in file:
        # Check if any phrase in the list appears in the line
        if any(phrase in line for phrase in phrases_to_find):
            # Print the line if it contains any of the phrases
            print(line.strip())
