
prob_vm=$1
compete_vm=$2
benchmark_time=20
latency_bench="/var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 30s -c 300 -t 16 https://127.0.0.1:8089/test.html" 
compete_bench="./cache_thr.out"
OUTPUT_FILE="./tests/acitivity_inaware-2$(date +%m%d%H%M).txt"

wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 32
    for i in {0..31};do
        sudo virsh vcpupin $select_vm $i $i
    done
    sleep 2
}

ssh ubuntu@$prob_vm "sudo killall nginx"
ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
sleep 4
ssh ubuntu@$prob_vm "sudo killall mysqld"

wake_and_pin_vm $prob_vm
wake_and_pin_vm $compete_vm

#Fetch VM PID and use that to fetch Cgroup title
vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')

c_vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$compete_vm.xml | awk -F "'" '{print $6}' | head -n 1)
c_vm_cgroup_title=$(sudo cat /proc/$c_vm_pid/cgroup | awk -F "/" '{print $3}')
ssh ubuntu@$compete_vm "sudo killall ./cache_thr.out"

ssh ubuntu@$compete_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo killall a.out" 
ssh ubuntu@$compete_vm "sudo $compete_bench" &
ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 
echo "finished warming up"



sudo echo 32000000 > /sys/kernel/debug/sched/min_granularity_ns

sudo echo 500000 > /sys/kernel/debug/sched/migration_cost_ns

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 

sudo echo 400000 > /sys/kernel/debug/sched/migration_cost_ns

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 

sudo echo 300000 > /sys/kernel/debug/sched/migration_cost_ns

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 

sudo echo 200000 > /sys/kernel/debug/sched/migration_cost_ns

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 

sudo echo 100000 > /sys/kernel/debug/sched/migration_cost_ns

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 

sudo echo 0 > /sys/kernel/debug/sched/migration_cost_ns

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 


sudo echo 3000000 > /sys/kernel/debug/sched/min_granularity_ns

sudo echo 500000 > /sys/kernel/debug/sched/migration_cost_ns

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 

sudo echo 400000 > /sys/kernel/debug/sched/migration_cost_ns

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 

sudo echo 300000 > /sys/kernel/debug/sched/migration_cost_ns

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 

sudo echo 200000 > /sys/kernel/debug/sched/migration_cost_ns

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 

sudo echo 100000 > /sys/kernel/debug/sched/migration_cost_ns

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 

sudo echo 0 > /sys/kernel/debug/sched/migration_cost_ns

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 





sudo git add .;sudo git commit -m 'new';sudo git push


