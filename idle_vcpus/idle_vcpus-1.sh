
prob_vm=$1
compete_vm=$2
compete_vm_2=$3
benchmark_time=20
latency_bench="sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p streamcluster -n 16 -i native"
idler_bench="sudo bash /home/ubuntu/idle_load_generator/idler.sh"
compete_bench="sudo sysbench --threads=32 --time=1000000 cpu run"
get_lat_val="cd /home/ubuntu/Workloads/tailbench-v0.9/utilities;sudo python parselats-1.py ../img-dnn/lats.bin"
OUTPUT_FILE="./tests/idle_vcpu-1$(date +%m%d%H%M).txt"

wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 8
    for i in {0..7};do
        sudo virsh vcpupin $select_vm $i 20
    done
    sleep 2
}

wake_and_pin_vm1(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 8
    for i in {0..7};do
        sudo virsh vcpupin $select_vm $i 21
    done
    sleep 2
}

wake_and_pin_prob(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 16
    for i in {0..31};do
        sudo virsh vcpupin $select_vm $i $((i+20))
    done
    sleep 2
}




wake_and_pin_vm1 $compete_vm_2
wake_and_pin_vm $compete_vm
wake_and_pin_prob $prob_vm
#Fetch VM PID and use that to fetch Cgroup title
ssh ubuntu@$prob_vm "sudo sysbench --threads=64 --time=20 cpu run"
ssh ubuntu@$compete_vm "sudo killall sysbench" 
for i in {0..0};do
    echo "naive test" >> "$OUTPUT_FILE"
    ssh ubuntu@$compete_vm_2 "sudo sysbench --threads=8 --report-interval=3 --time=30000000 cpu run" >>"$OUTPUT_FILE" &
    ssh ubuntu@$compete_vm "sudo sysbench --threads=8 --report-interval=3 --time=30000000 cpu run" >>"$OUTPUT_FILE" &
    sleep 3
    ssh ubuntu@$prob_vm "$latency_bench" >> "$OUTPUT_FILE" 
    ssh ubuntu@$compete_vm "sudo killall sysbench"
    ssh ubuntu@$compete_vm_2 "sudo killall sysbench"
    echo "non-naive test" >> "$OUTPUT_FILE"
    #use progressive, interrutpible sysbench
   ssh ubuntu@$compete_vm_2 "sudo sysbench --threads=8 --report-interval=3 --time=30000000 cpu run" >>"$OUTPUT_FILE" &
    ssh ubuntu@$compete_vm "sudo sysbench --threads=8 --report-interval=3 --time=30000000 cpu run" >>"$OUTPUT_FILE" &
    sleep 3
    ssh ubuntu@$prob_vm "taskset -c 2-31 $latency_bench" >> "$OUTPUT_FILE" 
    ssh ubuntu@$compete_vm "sudo killall sysbench"
    ssh ubuntu@$compete_vm_2 "sudo killall sysbench"
done
sudo git add .;sudo git commit -m 'new';sudo git push
