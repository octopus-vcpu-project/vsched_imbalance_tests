for i in {0..15};do
    sudo virsh vcpupin e-vm3 $i $(((i % 8)))
done
