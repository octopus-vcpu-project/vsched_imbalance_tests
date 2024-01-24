
'This thread is to show that the linux scheduler currently does a poor job of inter-process/intra thread fairness in a VM with completely symmetrical,
competed for VCPUS. Note that the linux scheduler actually does do a fine job of intra process fairness.'


OUTPUT_FILE="./test/unfair$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./test/2-dis-hrd$(date +%m%d%H%M).txt"

wipe_clean(){
    local local_prob_vm=$1
    ssh ubuntu@"$local_prob_vm" "sudo killall sysbench"
    ssh ubuntu@"$local_prob_vm" "sudo killall joe.out"
}


prob_vm=$1
compete_vm=$2
compete_benchmark="sysbench --threads=32 --time=60000 cpu run"
cpu_benchmark="sysbench --threads=32 --time=60 cpu run"

sudo bash ../utility/cleanon_startup.sh $prob_vm 16
sudo bash ../utility/cleanon_startup.sh $compete_vm 8
#Fetch VM PID and use that to fetch Cgroup title
wipe_clean $prob_vm

for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $((i + 20))
    sudo echo $runtime $period > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
done




echo "test complete"
