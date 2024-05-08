declare -a io_benchmarks
declare -a cpu_benchmarks
prob_vm=$1
sudo bash ../utility/cleanon_startup.sh $prob_vm 8

OUTPUT_FILE="./data/smt_cpu-$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./tests/smt_io-$(date +%m%d%H%M).txt"


for i in {0..3};do
            if [ $((i % 2)) == 0 ]; then
                virsh vcpupin $prob_vm $((i)) $((i))
            else
                virsh vcpupin $prob_vm $((i)) $((i+79))
            fi
done

for i in {4..7};do
            if [ $((i % 2)) == 0 ]; then
                virsh vcpupin $prob_vm $((i)) $((i+16))
            else
                virsh vcpupin $prob_vm $((i)) $((i+95))
            fi
done

virsh vcpupin $prob_vm $((7)) $((28))
virsh vcpupin $prob_vm $((6)) $((28))
