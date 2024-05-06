
prob_vm=$1
compete_vm=$2
benchmark_time=20
swaption_test="sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p swaption -n 16 -i native"
streamcluster_bench="sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p swaption -n 16 -i native"

idler_bench="sudo bash /home/ubuntu/idle_load_generator/idler.sh"
compete_bench="sudo sysbench --threads=32 --time=1000000 cpu run"
get_lat_val="cd /home/ubuntu/Workloads/tailbench-v0.9/utilities;sudo python parselats-1.py ../img-dnn/lats.bin"
OUTPUT_FILE="./data/prio_inversion-$(date +%m%d%H%M).txt"


wake_and_pin_prob(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 16
    for i in {0..15};do
        sudo virsh vcpupin $select_vm $i $(((i % 8) + 10))
    done
    sleep 2
}




vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)

sudo echo 3000000 > /sys/kernel/debug/sched/min_granularity_ns
sudo echo 4000000 > /sys/kernel/debug/sched/wakeup_granularity_ns
wake_and_pin_prob $prob_vm
ssh ubuntu@$prob_vm "sudo sysbench --time=10 --threads=16 cpu run" 


ssh ubuntu@$prob_vm "sudo sysbench --time=10 --threads=16 cpu run" 

for i in {0..2};do
   ssh ubuntu@$prob_vm "sudo killall a.out" 
   ssh ubuntu@$prob_vm "sudo $idler_bench" &
   echo "naive test" >> "$OUTPUT_FILE"
   ssh ubuntu@$prob_vm "sudo $swaption_test" >> "$OUTPUT_FILE" 
   ssh ubuntu@$prob_vm "sudo $streamcluster_test" >> "$OUTPUT_FILE" 
   sleep 3
   ssh ubuntu@$prob_vm "sudo killall a.out" 
   ssh ubuntu@$prob_vm "sudo taskset -c 0-7 $idler_bench" &
   echo "non-naive test" >> "$OUTPUT_FILE"
   ssh ubuntu@$prob_vm "taskset -c 0-7 sudo $swaption_test" >> "$OUTPUT_FILE" 
   ssh ubuntu@$prob_vm "taskset -c 0-7 sudo $streamcluster_test" >> "$OUTPUT_FILE" 
   sleep 4
done

sudo echo 1000000 > /sys/kernel/debug/sched/min_granularity_ns

for i in {0..2};do
   ssh ubuntu@$prob_vm "sudo killall a.out" 
   echo "non idle-just run" >> "$OUTPUT_FILE"
   ssh ubuntu@$prob_vm "sudo $swaption_test" >> "$OUTPUT_FILE" 
   ssh ubuntu@$prob_vm "sudo $streamcluster_test" >> "$OUTPUT_FILE" 
   sleep 3
   ssh ubuntu@$prob_vm "sudo killall a.out" 
   echo "non idle-just run-smart" >> "$OUTPUT_FILE"
   ssh ubuntu@$prob_vm "taskset -c 0-7 sudo $swaption_test" >> "$OUTPUT_FILE" 
   ssh ubuntu@$prob_vm "taskset -c 0-7 sudo $streamcluster_test" >> "$OUTPUT_FILE" 
   sleep 4
done

sudo echo 3000000 > /sys/kernel/debug/sched/min_granularity_ns

sudo git add .;sudo git commit -m 'new';sudo git push


