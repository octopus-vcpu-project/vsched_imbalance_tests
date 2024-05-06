import re
import re

# Read the contents of the file
with open('data/obj-latency-noidle05031929.txt', 'r') as file:
    content = file.read()

# Split the content into chunks based on the "Set latency" lines
chunks = re.split(r'Set latency to \d+', content)[1:]
listoflists = [[],[],[],[],[],[],[]]
for chunk in chunks:
    lines = chunk.strip().split('\n')
    
    mean_sum = 0
    p95_sum = 0
    p99_sum = 0
    max_sum = 0
    count = 0
    
    for line in lines[1:]:
        if line.startswith('queue:'):
            values = re.findall(r'[\d.]+', line)
            if(count%5==4):
                printStr=""
                index = 0
                for thing in values:
                    if(thing == '95' or thing == '99'):
                        continue;
                    listoflists[index].append(thing)
                    index+=1
                
                print(values)
            mean_sum += float(values[0])
            p95_sum += float(values[1])
            p99_sum += float(values[2])
            count += 1
    
    if count > 0:
        mean_avg = mean_sum / count
        p95_avg = p95_sum / count
        p99_avg = p99_sum / count
        max_avg = max_sum / count

        print(f"queue: mean {mean_avg:.3f} ms | p95 {p95_avg:.3f} ms | p99 {p99_avg:.3f} ms | max {max_avg:.3f} ms")
output_str=""
output_list = []
for x in range(0,len(listoflists)):
    for y in range(0,len(listoflists[x])):
        if(y%3==0):
            print(output_str)
            output_list.append(output_str)
            output_str=""
        output_str+=listoflists[x][y]
        output_str+="/"
    print("vhat")
output_list.pop(0)
output_list.append(output_str)
for y in range(len(output_list)):
    output_str = '=SPLIT("'
    for x in range(4):
        output_str +=output_list[y+x*8]
        output_str += ", "
    output_str+='", ",")'
    print(output_str)
