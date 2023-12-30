
'This test is a mirror of test 1-asym-plc, as the first test shows the inability to place tasks correctly on an underloaded vm 
with asymmetric capacity, and this shows the performance penalites that such a deficit leads to.
A 16 cpu VM is ran with 12 cpus extremely contested and 4 vcpus moderately contested. Sysbench is ran unrestricted, and the linux
scheduler is left to do as it pleases,and in the second test sysbench is pinned to the better 4 vcpus. 

Outcome: Opt performs better

Runtime:1000s'

prob_vm=$1
compete_vm=$2
cpu_benchmark="sysbench --threads=4 --time=10 cpu run"
cpu_benchmark_opt="taskset -c 12-15 sysbench --threads=4 --time=10 cpu run"
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

#topology naive testing
OUTPUT_FILE="./tests/2-asym-naive-$(date +%m%d%H%M).txt"
for i in {0..50};do
    ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE"
done

#topology opt testing
OUTPUT_FILE="./tests/2-asym-opt-$(date +%m%d%H%M).txt"
for i in {0..50};do
    ssh ubuntu@$prob_vm "sudo $cpu_benchmark_opt" >> "$OUTPUT_FILE"
done

touch $OUTPUT_FILE
echo "Test cpc_aware 2-asym-perf is complete"
