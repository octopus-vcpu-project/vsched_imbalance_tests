
prob_vm=$1
compete_vm=$2
benchmark_time=20
latency_bench="cd /home/ubuntu/Workloads/Tailbench/tailbench;time sudo bash run.sh"
idler_bench="sudo taskset -c 0-3 bash /home/ubuntu/idle_load_generator/idler.sh"
compete_bench="sudo sysbench --threads=32 --time=1000000 cpu run"
get_lat_val="cd /home/ubuntu/Workloads/tailbench/utilities;sudo python parselats-1.py ../img-dnn/lats.bin"
OUTPUT_FILE="./tests/idle_vcpu-4-naive-$(date +%m%d%H%M).log"
OUTPUT_FILE1="./tests/idle_vcpu-4-SMRT-$(date +%m%d%H%M).log"
OUTPUT_FILE2="./tests/idle_vcpu-4-dflt-$(date +%m%d%H%M).log"


wake_and_pin_prob(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 8
    for i in {0..4};do
        sudo virsh vcpupin $select_vm $i $((i*20))
    done
    for i in {5..7};do
        sudo virsh vcpupin $select_vm $i $((i*20+1))
    done
    sleep 2
}


run_test_series(){
    benchmark=$1
    ssh ubuntu@$prob_vm "sudo killall a.out"
    sudo tee /sys/module/kvm/parameters/halt_poll_ns <<< 0
    echo "0(no) halt polling">> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$benchmark;sudo bash run.sh"
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$benchmark/lats.bin" >> "$OUTPUT_FILE" 
    sudo tee /sys/module/kvm/parameters/halt_poll_ns <<< 200000
    sleep 4
    echo "200000(standard) halt polling">> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$benchmark;sudo bash run.sh"
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$benchmark/lats.bin" >> "$OUTPUT_FILE" 
    sudo tee /sys/module/kvm/parameters/halt_poll_ns <<< 20000000
    sleep 4
    echo "20000000(mega high) halt polling" >> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$benchmark;sudo bash run.sh"
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$benchmark/lats.bin" >> "$OUTPUT_FILE" 
    sleep 4
    sudo tee /sys/module/kvm/parameters/halt_poll_ns <<< 200000
    echo "Clumped(0-4)">> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$benchmark;sudo taskset -c 0-3 bash run.sh"
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$benchmark/lats.bin" >> "$OUTPUT_FILE" 

    ssh ubuntu@$prob_vm "$idler_bench" &
    echo "W/ Idle Workload(naive)">> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$benchmark;sudo bash run.sh"
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$benchmark/lats.bin" >> "$OUTPUT_FILE" 

    echo "W/ Idle Workload(smart)">> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$benchmark;sudo taskset -c 0-3 bash run.sh"
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$benchmark/lats.bin" >> "$OUTPUT_FILE" 
}


vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)

wake_and_pin_prob $prob_vm
#wake_and_pin_prob $compete_vm
sleep 10 
#ssh ubuntu@$compete_vm "sudo killall sysbench"
#ssh ubuntu@$compete_vm "sudo sysbench --time=90000000 --threads=16 cpu run"  &
sleep 10 
run_test_series "img-dnn"
#run_test_series "moses"
#run_test_series "masstree"
#run_test_series "silo"
sudo git add .;sudo git commit -m 'new';sudo git push


