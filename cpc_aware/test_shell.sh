#!/bin/bash

FILE_PATH="/sys/kernel/debug/sched/debug"  # Replace with your file path

while true; do
    # Read the file and extract cpu_clk and .clock for cpu#0
    cpu_clk=$(grep 'cpu_clk' "$FILE_PATH" | awk '{print $3}' | cut -d. -f1 | head -n 1)

    # Extracting the .clock value specifically after cpu#0
    clock_cpu0=$(awk '/cpu#0,/{flag=1;next}/^$/{flag=0}flag && /.clock[^_]/' "$FILE_PATH" | awk '{print $3}' | cut -d. -f1 | h>

    # Calculate the difference and check if it's greater than 100
    if [[ ! -z "$cpu_clk" && ! -z "$clock_cpu0" ]]; then
        difference=$((cpu_clk - clock_cpu0))
        echo $cpu_clk
        echo $clock_cpu0
        echo $difference
        if [[ $difference -gt 10 ]]; then
            echo "WARNING: Difference is $difference which is greater than 100"
        fi
    fi

    sleep 0.1  # Check every 100 milliseconds
done
















