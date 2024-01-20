
'This test is a mirror of test 1-asym-plc, as the first test shows the inability to place tasks correctly on an underloaded vm 
with asymmetric capacity, and this shows the performance penalites that such a deficit leads to.
A 16 cpu VM is ran with 12 cpus extremely contested and 4 vcpus moderately contested. Sysbench is ran unrestricted, and the linux
scheduler is left to do as it pleases,and in the second test sysbench is pinned to the better 4 vcpus. 

Outcome: Opt performs better

Runtime:1000s'

prob_vm=$1
compete_vm=$2
compete_vm2=$3
compete_vm3=$4
cpu_benchmark="sysbench --threads=4 --time=10 cpu run"
compete_benchmark="sysbench --threads=32 --time=5000 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 16 $compete_vm 32 $compete_vm2 32 $compete_vm3 32

for i in {0..11};do
    sudo virsh vcpupin $prob_vm $i $i
    sudo virsh vcpupin $compete_vm $i $((i+40))
    sudo virsh vcpupin $compete_vm2 $i $i
    sudo virsh vcpupin $compete_vm3 $i $i
done

for i in {12..15};do
    sudo virsh vcpupin $compete_vm $i $i
    sudo virsh vcpupin $prob_vm $i $i
    sudo virsh vcpupin $compete_vm2 $i $((i%12))
    sudo virsh vcpupin $compete_vm3 $i $((i%12))
done

for i in {16..23};do
    sudo virsh vcpupin $compete_vm2 $i $(( i%12 ))
    sudo virsh vcpupin $compete_vm3 $i $(( i%12 ))
    sudo virsh vcpupin $compete_vm $i $((i+40))
done

for i in {24..31};do
    sudo virsh vcpupin $compete_vm2 $i $(( i+40 ))
    sudo virsh vcpupin $compete_vm3 $i $(( i+40 ))
    sudo virsh vcpupin $compete_vm $i $((i+40))
done

echo "Finished Pinning"

ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo killall joe.out" 
ssh ubuntu@$compete_vm "sudo killall sysbench"
ssh ubuntu@$compete_vm2 "sudo killall sysbench"
ssh ubuntu@$compete_vm3 "sudo killall sysbench"

ssh ubuntu@$compete_vm "sudo $compete_benchmark" &
ssh ubuntu@$compete_vm2 "sudo $compete_benchmark" &
ssh ubuntu@$compete_vm3 "sudo $compete_benchmark" &

OUTPUT_FILE="./tests/1-asym-perf-smart-$(date +%m%d%H%M).txt"

ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/cpu_profiler/setup_vcapacity.sh"
ssh ubuntu@$prob_vm "nohup sudo /home/ubuntu/cpu_profiler/joe.out -v -i 500 -s 10000 &  " & 

sleep 4
for i in {0..25};do
	ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE"
done
touch $OUTPUT_FILE

echo "Test cpc_aware 1-asym-plc is complete"
