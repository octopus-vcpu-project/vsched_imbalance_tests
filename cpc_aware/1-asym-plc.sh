
'This test is to determine how tasks are placed incorrectly in a VM with asymmetric capacity. The setup is that the 
probing VM has 16 cores, with 4 of them moderately contested for and 12 of them extremely contested for. The Sched/debug
text file is then periodically read every 0.5 seconds to see location, and a python file at the end is used to calculate
location placement to get an idea of the distribution of threads


Outcome: Since the task we are running in sysbench is only 4 threads, the task should only go to the 4 threads that are moderately contested for
Ideally, it should also stay there. But in the current system it will go all over the place.

Runtime:250s'


prob_vm=$1
compete_vm=$2
cpu_benchmark="sysbench --threads=4 --time=2000 cpu run"
compete_benchmark="sysbench --threads=52 --time=2000 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 16 $compete_vm 52

for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $i
    sudo virsh vcpupin $compete_vm $i $i
done

for i in {16..51};do
    sudo virsh vcpupin $compete_vm $i $(( i%12 ))
done

echo "Finished Pinning"

ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$compete_vm "sudo killall sysbench"
ssh ubuntu@$compete_vm "sudo $compete_benchmark" &
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" &

OUTPUT_FILE="./tests/1-asym-plc-$(date +%m%d%H%M).txt"
for i in {0..500};do
    sleep 0.5
    ssh ubuntu@$prob_vm "sudo cat /sys/kernel/debug/sched/debug | grep -E 'cpu#|>R '" >> "$OUTPUT_FILE"
done
touch $OUTPUT_FILE
echo "Test cpc_aware 1-asym-plc is complete"
