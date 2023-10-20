#!/bin/bash

# Function to set the vCPU count for a VM if needed and restart if necessary
set_vcpu() {
    local vm=$1
    local target_vcpu_count=$2

    # Get the current vCPU counts
    local max_vcpu_count=$(virsh vcpucount "$vm" --maximum)

    # If the maximum vCPU count is different, set it and restart the VM (if it's running)
    if [ "$max_vcpu_count" -ne "$target_vcpu_count" ]; then
        if virsh list --state-running --name | grep -q "^$vm$"; then
            virsh shutdown "$vm"
            while true; do
            vm_state=$(virsh domstate "$vm")
            if [ "$vm_state" != "running" ]; then
                echo "VM is shutdown"
                break
            else
                echo "Waiting for VM to shutdown"
                sleep 3 
            fi
            done
            
        fi

        # Set the vCPU count

        virsh setvcpus "$vm" "$target_vcpu_count" --config --maximum
        virsh setvcpus "$vm" "$target_vcpu_count" --config
        # Start the VM again if it was running before
        virsh start "$vm"
        while true; do
        # Get the state of the specific VM
        vm_state=$(virsh domstate "$vm")
        

        if [[ "$vm_state" == "running" ]]; then
            echo "VM is now running."
            ssh_output=$(ssh -o ConnectTimeout=10 ubuntu@$vm "exit" 2>&1)
            ssh_status=$?
        
            if [ $ssh_status -eq 0 ]; then
                echo "VM is accessible via SSH."
                break
            else
                echo "VM is running but not accessible via SSH yet. SSH Output: $ssh_output. Retrying..."
            fi
                
            else
            echo "Waiting for VM to start..."
            sleep 3 
        fi
        done
    fi
}

# Get a list of all running VMs
running_vms=$(virsh list --state-running --name)

# Process input arguments
while [ "$#" -gt 0 ]; do
    vm="$1"
    vcpu_count="$2"
    set_vcpu "$vm" "$vcpu_count"
    shift 2  # Shift past the VM and its vCPU count

    if ! echo "$running_vms" | grep -q "^$vm$"; then
        echo "Starting VM: $vm"
        virsh start "$vm"
        while true; do
        # Get the state of the specific VM
        vm_state=$(virsh domstate "$vm")
        

        if [[ "$vm_state" == "running" ]]; then
            echo "VM is now running."
            ssh_output=$(ssh -o ConnectTimeout=10 ubuntu@$vm "exit" 2>&1)
            ssh_status=$?
        
            if [ $ssh_status -eq 0 ]; then
                echo "VM is accessible via SSH."
                break
            else
                echo "VM is running but not accessible via SSH yet. SSH Output: $ssh_output. Retrying..."
            fi
                
            else
            echo "Waiting for VM to start..."
            sleep 3 
        fi
        done
        
    else
        echo "VM $vm is already running."
    fi

    # Set the vCPU count for the VM
    
done