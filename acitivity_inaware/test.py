import re
import re

# Read the contents of the file
with open('data/output_parse.txt', 'r') as file:
    content = file.read()

# Split the content into chunks based on the "Set latency" lines
chunks = re.split(r'Set latency to \d+', content)[1:]

for chunk in chunks:
    lines = chunk.strip().split('\n')
    latency = re.findall(r'\d+', lines[0])[0]
    
    mean_sum = 0
    p95_sum = 0
    p99_sum = 0
    max_sum = 0
    count = 0
    
    for line in lines[1:]:
        if line.startswith('queue:'):
            values = re.findall(r'[\d.]+', line)
            print(values)
            mean_sum += float(values[0])
            p95_sum += float(values[1])
            p99_sum += float(values[2])
#            max_sum += float(values[7])
            count += 1
    
    if count > 0:
        mean_avg = mean_sum / count
        p95_avg = p95_sum / count
        p99_avg = p99_sum / count
        max_avg = max_sum / count
        
        print(f"Set latency to {latency}")
        print(f"queue: mean {mean_avg:.3f} ms | p95 {p95_avg:.3f} ms | p99 {p99_avg:.3f} ms | max {max_avg:.3f} ms")
        print()
