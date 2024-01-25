



prob_vm=$1
compete_vm1=$2
compete_vm2=$3
compete_vm3=$4
benchmark_time=20
main_command="sysbench --threads=32 --time=30000 cpu run"

OUTPUT_FILE="./tests/acitivity_inaware-1$(date +%m%d%H%M).txt"

wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 16
    for i in {0..15};do
        sudo virsh vcpupin $select_vm $i $i
    done
    sleep 2
}
wake_and_pin_vm $prob_vm

ssh ubuntu@$prob_vm "sudo python /home/ubuntu/bpftrace/bcc/tools/runqlat.py ">> "$OUTPUT_FILE" &
ssh ubuntu@$prob_vm "sudo $main_command" &
sleep $benchmark_time

ssh ubuntu@$prob_vm "sudo kill -s SIGINT \$(pidof python)"
sleep $benchmark_time
wake_and_pin_vm $compete_vm1
ssh ubuntu@$compete_vm1 "sudo $main_command" &
ssh ubuntu@$prob_vm "sudo python /home/ubuntu/bpftrace/bcc/tools/runqlat.py ">> "$OUTPUT_FILE" &
sleep $benchmark_time
ssh ubuntu@$prob_vm "sudo kill -s SIGINT \$(pidof python)"
sleep 3
wake_and_pin_vm $compete_vm2
ssh ubuntu@$compete_vm2 "sudo $main_command" &
ssh ubuntu@$prob_vm "sudo python /home/ubuntu/bpftrace/bcc/tools/runqlat.py ">> "$OUTPUT_FILE" &
sleep $benchmark_time
ssh ubuntu@$prob_vm "sudo kill -s SIGINT \$(pidof python)"
sleep 3
wake_and_pin_vm $compete_vm3
ssh ubuntu@$compete_vm3 "sudo $main_command" &
ssh ubuntu@$prob_vm "sudo python /home/ubuntu/bpftrace/bcc/tools/runqlat.py ">> "$OUTPUT_FILE" &
sleep $benchmark_time
ssh ubuntu@$prob_vm "sudo kill -s SIGINT \$(pidof python)"
sleep 3
ssh ubuntu@$prob_vm "sudo killall sysbench"
virsh shutdown $compete_vm1
virsh shutdown $compete_vm2
virsh shutdown $compete_vm3

sudo git add .;sudo git commit -m 'new';sudo git push


