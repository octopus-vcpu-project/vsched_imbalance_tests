
'This thread is to show that the linux scheduler currently does a poor job of inter-process/intra thread fairness in a VM with completely symmetrical,
competed for VCPUS. Note that the linux scheduler actually does do a fine job of intra process fairness.'


OUTPUT_FILE="./test/freq-unfair$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./test/freq-unfair$(date +%m%d%H%M).txt"

prob_vm=$1
compete_vm=$2
compete_vm1=$3
cpu_benchmark="sysbench --threads=32 --time=40 cpu run"
compete_benchmark="sysbench --threads=8 --time=10000 cpu run"

wipe_clean(){
    local local_prob_vm=$1
    ssh ubuntu@"$local_prob_vm" "sudo killall sysbench"
    ssh ubuntu@"$local_prob_vm" "sudo killall joe.out"
}


sudo bash ../utility/cleanon_startup.sh $prob_vm 16
sudo bash ../utility/cleanon_startup.sh $compete_vm 8


for i in {0..7};do
    sudo virsh vcpupin $compete_vm $i $((i))
done

for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $((i + 8))
done


wipe_clean $prob_vm
ssh ubuntu@$prob_vm "sudo $compete_benchmark" >> "$OUTPUT_FILE" &
sleep 5
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE" &
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE2" 
ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/cpu_profiler/setup_vcapacity.sh"
ssh ubuntu@$prob_vm "nohup sudo /home/ubuntu/cpu_profiler/cpu_profiler.out -v -i 5 -s 15000 &  " & 
sleep 10 
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE" &
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE2" 