prob_vm=$1
for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $((i))
done

for i in {16..31};do
    sudo virsh vcpupin $prob_vm $i $((i+4))
done
