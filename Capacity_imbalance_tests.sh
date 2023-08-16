
#!/bin/bash


if [ "$#" -ne 2 ]; then
    echo "VM names not supplied, Assuming default VM specs"
    prob_vm="e-vm1"
    compete_vm1="vm1"
    compete_vm2="e-vm3"
else
    prob_vm=$1
    compete_vm1=$2
    compete_vm2=$3
fi

for vm in $prob_vm $compete_vm1 $compete_vm2; do
    vm_status=$(virsh list --all | grep -w "$vm" | awk '{print $3$4}')
    if [ "$vm_status" != "running" ]; then
        echo "Starting $vm..."
        virsh start $vm
    else
        echo "$vm is running"
    fi
done


benchmark_path="/home/ubuntu/Workloads/parsec-benchmark/bin/"


#Check that everything is set up properly
for vm in $prob_vm $compete_vm1 $compete_vm2; do
    echo "Testing SSH for $vm..."

    # Attempt to SSH into VM with a timeout of 10 seconds
    ssh -o ConnectTimeout=10 ubuntu@$vm echo "SSH success"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to SSH into $vm"
        exit 1
    fi

    # Check if sudo requires no password on VM
    ssh ubuntu@$vm "echo 'checking sudo' && sudo -n true"
    if [ $? -ne 0 ]; then
        echo "Error: Sudo requires a password on $vm or the user does not have sudo privileges."
        exit 1
    fi
done

ssh ubuntu@$compete_vm1 "sudo killall sysbench" &

ssh ubuntu@$compete_vm1 "sudo killall a.out" &
ssh ubuntu@$compete_vm2 "sudo killall sysbench" &
ssh ubuntu@$compete_vm2 "sudo killall a.out" &
ssh ubuntu@$prob_vm "sudo killall bodytrack" &

# Among 16 cores of measuring VM, set the environment for 8 cores so that they receive 33% of the total capacity of the physical CPUs.
for i in {0..15}; do
    virsh vcpupin $prob_vm $i $i
    virsh vcpupin $compete_vm1 $i $((i%8))
done

for i in {0..63}; do
    virsh vcpupin $compete_vm2 $i $i
done

#Engage workload in competition
ssh ubuntu@$compete_vm2 "sysbench --threads=64 --time=100000 cpu run" &
ssh ubuntu@$compete_vm1 "sysbench --threads=16 --time=100000 cpu run" &

# Run sysbench with 2*16 threads for 180 seconds
OUTPUT_FILE="cpc_test_1_naive$(date +%Y%m%d%H%M%S).txt"
echo "Running Bodytrack with 2*16 threads for 180 seconds...(naive)"
sleep 3
ssh ubuntu@$prob_vm "sudo $benchmark_path/parsecmgmt -a run -p bodytrack -n 32 -i native" > "$OUTPUT_FILE"

# Run sysbench with 2*16 threads for 180 seconds, pinned so that the cores that aren't competed for get three threads, and the cores that are competed for get one thread.
OUTPUT_FILE="cpc_test_1_smart$(date +%Y%m%d%H%M%S).txt"
echo "Running sysbench with 2*16 threads for 180 seconds...(smart)"
sleep 1
ssh -T ubuntu@$prob_vm <<'ENDSSH' > "$OUTPUT_FILE"
sudo su 

benchmark_path="/home/ubuntu/Workloads/parsec-benchmark/bin/"
$benchmark_path/parsecmgmt -a run -p bodytrack -n 64 -i native &
sleep 10
SYSBENCH_PID=$(pidof bodytrack)
echo "Sysbench PID: $SYSBENCH_PID"
TID_ARRAY=($(ls /proc/$SYSBENCH_PID/task/))
echo "Thread IDs: ${TID_ARRAY[@]}"

#Pin the first 8 threads 1-1 to CPUs 0-7
for i in {0..7}; do
    taskset -c -p $i ${TID_ARRAY[$i]}
done

# Pin the next 24 threads in groups of 3 to CPUs 8-15
CPU=8
for i in {8..31}; do
    taskset -c -p $CPU ${TID_ARRAY[$i]t
    if [ $(( (i - 7) % 3 )) -eq 0 ]; then
        ((CPU++))
    fi
done

# Wait for sysbench to complete
wait $SYSBENCH_PID
ENDSSH




echo "Finished"
