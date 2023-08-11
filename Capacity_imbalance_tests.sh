
#!/bin/bash


if [ "$#" -ne 2 ]; then
    echo "VM names not supplied, Assuming default VM specs"
    prob_vm="e-vm1"
    compete_vm1="e-vm3"
    compete_vm2="vm1"
else
    prob_vm=$1
    compete_vm1=$2
    compete_vm2=$3
fi
# Start VMs (three with 16 cores)
echo "Starting VMs..."
virsh start $prob_vm
virsh start $compete_vm1
virsh start $compete_vm2

#Ensure that the core amount is correct
for vm in $prob_vm $compete_vm1 $compete_vm2; do
    virsh setvcpus $vm 16 --live --config
    if [ $? -ne 0 ]; then
        echo "Maximum CPU value for VMs must be at least 16"
        exit 1
    fi
done

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

# Among 16 cores of measuring VM, set the environment for 8 cores so that they receive 33% of the total capacity of the physical CPUs.
for i in {0..15}; do
    virsh vcpupin $prob_vm $i $i
    virsh vcpupin $compete_vm1 $i $((i%8))
    virsh vcpupin $compete_vm2 $i $((i%8))
done


#Engage workload in competition
ssh ubuntu@$compete_vm1 "sysbench cpu --threads=16 --time=100000 cpu run" &
ssh ubuntu@$compete_vm2 "sysbench cpu --threads=16 --time=100000 cpu run" &

# Run sysbench with 2*16 threads for 180 seconds
OUTPUT_FILE="cpc_test_1_naive$(date +%Y%m%d%H%M%S).txt"
echo "Running sysbench with 2*16 threads for 180 seconds..."
ssh ubuntu@$prob_vm "sysbench --time=180 --threads=32 cpu run" > "$OUTPUT_FILE"


# Run sysbench with 2*16 threads for 180 seconds, pinned so that the cores that aren't competed for get three threads, and the cores that are competed for get one thread.
OUTPUT_FILE="cpc_test_1_smart$(date +%Y%m%d%H%M%S).txt"
ssh ubuntu@$prob_vm <<'ENDSSH' > "$OUTPUT_FILE"
sysbench --time=180 --threads=32 cpu run &

SYSBENCH_PID=$!

# Sleep for a brief moment to ensure sysbench has started
sleep 1

TID_ARRAY=($(pgrep -w -l -P $SYSBENCH_PID | awk '{print $1}'))

# Pin the first 8 threads 1-1 to CPUs 0-7
for i in {0..7}; do
    taskset -pc $i ${TID_ARRAY[$i]}
done

# Pin the next 24 threads in groups of 3 to CPUs 8-15
CPU=8
for i in {8..31}; do
    taskset -pc $CPU ${TID_ARRAY[$i]}
    # Check if it's time to switch to the next CPU
    if [ $(( (i - 7) % 3 )) -eq 0 ]; then
        ((CPU++))
    fi
done

# Wait for sysbench to complete
wait $SYSBENCH_PID
ENDSSH

wait
echo "Script execution completed!"
