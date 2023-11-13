
prob_vm=$1
compete_vm=$2
benchmark_time=20
latency_bench="cd /home/ubuntu/Workloads/Tailbench/tailbench;time sudo bash run.sh"
idler_bench="sudo taskset -c 0-15 bash /home/ubuntu/idle_load_generator/idler.sh"
compete_bench="sudo sysbench --threads=32 --time=1000000 cpu run"
get_lat_val="cd /home/ubuntu/Workloads/tailbench/utilities;sudo python parselats-1.py ../img-dnn/lats.bin"
OUTPUT_FILE="./tests/idle_vcpu-4-naive-$(date +%m%d%H%M).log"
OUTPUT_FILE1="./tests/idle_vcpu-4-SMRT-$(date +%m%d%H%M).log"
OUTPUT_FILE2="./tests/idle_vcpu-4-dflt-$(date +%m%d%H%M).log"


wake_and_pin_prob(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 32
    for i in {0..15};do
        sudo virsh vcpupin $select_vm $i $((i+20))
    done
    sleep 2
}


run_test_series(){
    benchmark=$1
    ssh ubuntu@$prob_vm "sudo killall a.out"
    sudo tee /sys/module/kvm/parameters/halt_poll_ns <<< 2000000
    echo "2000000(high) halt polling" >> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$benchmark;sudo bash run.sh"
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$benchmark/lats.bin" >> "$OUTPUT_FILE" 
    sudo tee /sys/module/kvm/parameters/halt_poll_ns <<< 0
    
    echo "0(no) halt polling">> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$benchmark;sudo bash run.sh"
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$benchmark/lats.bin" >> "$OUTPUT_FILE" 

    sudo tee /sys/module/kvm/parameters/halt_poll_ns <<< 200000
    echo "200000(standard) halt polling">> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$benchmark;sudo bash run.sh"
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$benchmark/lats.bin" >> "$OUTPUT_FILE" 

    ssh ubuntu@$prob_vm "$idler_bench"
    echo "W/ Idle Workload(naive)">> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$benchmark;sudo bash run.sh"
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/utilities;sudo python parselats-1.py ../$benchmark/lats.bin" >> "$OUTPUT_FILE" 

    echo "W/ Idle Workload(smart)">> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$benchmark;sudo taskset -c 0-16 bash run.sh"
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$benchmark/lats.bin" >> "$OUTPUT_FILE" 
}


vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)

virsh shutdown $prob_vm
virsh shutdown $compete_vm
virsh start $prob_vm
virsh start $compete_vm
wake_and_pin_prob $prob_vm
wake_and_pin_prob $compete_vm
sleep 10 
ssh ubuntu@$compete_vm "sudo sysbench --time=90000000 --threads=32 cpu run"  &
run_test_series "img-dnn"
sudo git add .;sudo git commit -m 'new';sudo git push


