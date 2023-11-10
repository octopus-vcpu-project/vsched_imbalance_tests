
prob_vm=$1
compete_vm=$2
benchmark_time=20
latency_bench="cd /home/ubuntu/Workloads/tailbench-v0.9/img-dnn;time sudo bash run.sh"
idler_bench="sudo bash /home/ubuntu/idle_load_generator/idler.sh"
compete_bench="sudo sysbench --threads=32 --time=1000000 cpu run"
get_lat_val="cd /home/ubuntu/Workloads/tailbench-v0.9/utilities;sudo python parselats-1.py ../img-dnn/lats.bin"
OUTPUT_FILE="./tests/idle_vcpu-4-naive-$(date +%m%d%H%M).log"
OUTPUT_FILE1="./tests/idle_vcpu-4-SMRT-$(date +%m%d%H%M).log"


wake_and_pin_prob(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 16
    for i in {0..15};do
        sudo virsh vcpupin $select_vm $i $((i+20))
    done
    sleep 2
}




vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)


wake_and_pin_prob $prob_vm
wake_and_pin_prob $compete_vm
ssh ubuntu@$compete_vm "sudo sysbench --time=90000000 --threads=16 cpu run"  &
#Fetch VM PID and use that to fetch Cgroup title
for i in {0..0};do
   echo "naive test" >> "$OUTPUT_FILE"
   ssh ubuntu@$prob_vm "cd Workloads;cd rt-app;sudo rt-app rtest.json" >> "$OUTPUT_FILE" 
   scp ubuntu@$prob_vm:/home/ubuntu/Workloads/rt-app/test_logs/rt-app-smrt-thread0-0.log $OUTPUT_FILE
   sleep 3
   echo "non-naive test" >> "$OUTPUT_FILE"
   ssh ubuntu@$prob_vm "cd Workloads;cd rt-app;sudo rt-app rtest1.json" >> "$OUTPUT_FILE" 
   scp ubuntu@$prob_vm:/home/ubuntu/Workloads/rt-app/test_logs/rt-app-naive-thread0-0.log $OUTPUT_FILE1
   sleep 4
done
ssh ubuntu@$compete_vm "killall sysbench" 
sudo git add .;sudo git commit -m 'new';sudo git push


