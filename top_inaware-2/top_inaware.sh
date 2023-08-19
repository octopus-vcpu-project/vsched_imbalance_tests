prob_vm = $1
benchmark_command = "sysbench --threads=16 --time=100 cpu run"
../utility/cleanon_startup.sh prob_vm 32

for i in {0..31};do
    if [$i%2 -eq 0] then
        sudo virsh vcpupin $i $((i / 2))
    else
        sudo virsh vcpupin $i $((( (i-1) / 2) + 80))
    fi
done

ssh ubuntu@$prob_vm "sudo killall sysbench" &

#topology naive testing
OUTPUT_FILE="top_inaware_naive$(date +%Y%m%d%H%M%S).txt"
ssh ubuntu@$prob_vm "sudo $benchmark_command" > "$OUTPUT_FILE"

#topology smart testing
OUTPUT_FILE="top_inaware_smart$(date +%Y%m%d%H%M%S).txt"
ssh -T ubuntu@$prob_vm <<'ENDSSH' > "$OUTPUT_FILE"
    sudo su 
    sysbench --threads=16 --time=100 cpu run
    sleep 1
    SYSBENCH_PID=$(pidof sysbench)
    echo "Sysbench PID: $SYSBENCH_PID"
    TID_ARRAY=($(ls /proc/$SYSBENCH_PID/task/))
    echo "Thread IDs: ${TID_ARRAY[@]}"

    #Pin the first 8 threads 1-1 to CPUs 0-7
    for i in {0..15}; do
        taskset -c -p $i ${TID_ARRAY[$i]}
    done
    # Wait for sysbench to complete
    wait $SYSBENCH_PID
ENDSSH