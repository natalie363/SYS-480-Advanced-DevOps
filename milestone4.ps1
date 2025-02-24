get-vm
Write-Host ""
$selectedVM = Read-Host "Enter the name of the VM that should be cloned"
$newName = Read-Host "Enter the new VM's name"
$cloneType = Read-Host "Enter 'F' for full clone or 'L' for linked clone"
$vm = Get-VM -Name $selectedVM
$snapshot = Get-Snapshot -vm $vm -Name "base"
$vmhost = Get-VMHost -Name "super3.eckles.local"
$ds = Get-Datastore -Name "datastore1"
If ($cloneType -eq "F"){
        $linkedname = "{0}.linked" -f $vm.name
        $linkedvm = New-VM -LinkedClone -Name $linkedName -VM $vm -ReferenceSnapshot $sna>
        $newvm = New-VM -Name $newName -VM $linkedvm -VMHost $vmhost -Datastore $ds
        $newvm | new-snapshot -Name "base"
        $linkedvm | Remove-VM -Confirm:$false
        }
Elseif ($cloneType -eq "L"){
        $linkedvm = New-VM -LinkedClone -Name $newName -VM $vm -ReferenceSnapshot $snapsh>
        $linkedvm | new-snapshot -Name "base"
        }
else {
        write-host "Invalid selection, program ending"
        }
