
for i in {0..31};do
        virsh vcpupin e-vm3 $((i)) $((i))
done
