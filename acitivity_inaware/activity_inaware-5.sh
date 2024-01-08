
prob_vm=$1
compete_vm=$2
benchmark_time=20
jumper_bench="sudo sysbench --threads=1 --time=30 cpu run" 
compete_bench="./cache_thr.out"
OUTPUT_FILE="./tests/acitivity_inaware-5$(date +%m%d%H%M).txt"
naive_topology_string="<cpu mode='custom' match='exact' check='none'>\n<model fallback='forbid'>qemu64</model>\n</cpu>"

wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 16
    for i in {0..15};do
        sudo virsh vcpupin $select_vm $i $((i))
    done
    sleep 2
}

setMigrationCost(){
    sudo echo $1 > /sys/kernel/debug/sched/migration_cost_ns
    echo "Set Migration Cost to $1" 
    echo "Set Migration Cost to $1" >> "$OUTPUT_FILE" 
}




wake_and_pin_vm $prob_vm

#Fetch VM PID and use that to fetch Cgroup title
vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')


setLatencyCFS(){
    set_latency=$1
    total_period=$2
    ssh ubuntu@$prob_vm "sudo killall sysbench" 
    for i in {0..15};do
        sudo echo $1 $2 > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    echo "Set latency cfs to $1" 
    echo "Set latency cfs to $1" >> "$OUTPUT_FILE" 
}


setLatencyCFS 400000 800000

ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo killall a.out" 
ssh ubuntu@$prob_vm "sudo $jumper_bench"  >> "$OUTPUT_FILE" 


num_cores=$(nproc)

# Initialize variable i to 0
i=0

# Start sysbench CPU test in the background
sysbench cpu --threads=1 run & >> "$OUTPUT_FILE" 
sysbench_pid=$!

# Loop to change the CPU core for sysbench every 4 milliseconds
while [ -e /proc/$sysbench_pid ]; do
  # Compute the CPU core to set
  target_core=$(( (i + 1) % num_cores ))

  # Use taskset to set the CPU affinity for sysbench
  taskset -cp $target_core $sysbench_pid > /dev/null

  # Increment i
  i=$((i + 1))

  # Sleep for 4 milliseconds
  sleep 0.004
done


sudo git add .;sudo git commit -m 'new';sudo git push


