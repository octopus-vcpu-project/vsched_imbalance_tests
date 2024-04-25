
for i in {0..7};do
        virsh vcpupin e-vm3 $((i)) $((i))
done

for i in {8..15};do
	virsh vcpupin e-vm3 $((i)) $((i+72))
done

for i in {0..7};do
        virsh vcpupin vsched-1 $((i)) $((i))
done

for i in {8..15};do
        virsh vcpupin vsched-1 $((i)) $((i+72))
done
