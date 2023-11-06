
prob_vm=$1
compete_vm=$2
benchmark_time=20
latency_bench="cd /home/ubuntu/Workloads/tailbench-v0.9/img-dnn;time sudo bash run.sh"
idler_bench="sudo bash /home/ubuntu/idle_load_generator/idler.sh"
compete_bench="sudo sysbench --threads=32 --time=1000000 cpu run"
get_lat_val="cd /home/ubuntu/Workloads/tailbench-v0.9/utilities;sudo python parselats-1.py ../img-dnn/lats.bin"
OUTPUT_FILE="./tests/idle_vcpu-1$(date +%m%d%H%M).txt"

wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 1
    for i in {0..1};do
        sudo virsh vcpupin $select_vm $i 20
    done
    sleep 2
}

wake_and_pin_prob(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 16
    for i in {0..15};do
        sudo virsh vcpupin $select_vm $i $((i+20))
    done
    sleep 2
}





wake_and_pin_vm $compete_vm
wake_and_pin_prob $prob_vm
#Fetch VM PID and use that to fetch Cgroup title
ssh ubuntu@$compete_vm "sudo killall sysbench" 
for i in {0..4};do
    echo "naive test" >> "$OUTPUT_FILE"
    ssh ubuntu@$compete_vm "sudo sysbench --threads=1 --time=30 cpu run" >>"$OUTPUT_FILE" &
    ssh ubuntu@$prob_vm "sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p bodytrack -n 32 -i native" >> "$OUTPUT_FILE" 

    echo "non-naive test">> "$OUTPUT_FILE"
    #use progressive, interrutpible sysbench
    ssh ubuntu@$compete_vm "sudo sysbench --threads=1 --time=30 cpu run" >>"$OUTPUT_FILE" &
    ssh ubuntu@$prob_vm "taskset -c 1-15 sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p bodytrack -n 32 -i native" >> "$OUTPUT_FILE" 

sudo git add .;sudo git commit -m 'new';sudo git push


