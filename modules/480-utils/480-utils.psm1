function 480Banner() {
    Write-Host "Hello SYS480"
}

function 480Connect([string] $server){
    $conn = $global:DefaultVIServer
    if ($conn){
        $msg = "Already connected to: {0}" -f $conn
        Write-Host -ForegroundColor Green $msg
    } 
    else{
        $conn = Connect-VIServer -Server $server
    }
}

function Get-480Config([string] $config_path){
    $conf = $null
    if(Test-Path $config_path){
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
    }
    else{
        Write-Host -ForegroundColor "yellow" "No configuration found"
    }
    return $conf
}

function Select-VM([string] $folder){
    
    $selected_vm = $null

    try{
        $vms = Get-VM -Location $folder
        [int] $index = 1
        foreach($vm in $vms){
            Write-Host [$index] $vm.Name
            $index += 1
        }
    }
    catch{
        Write-Host "Invalid Folder: $folder" -ForegroundColor "Red"

    }
    try{
        [int] $index_selected = Read-Host "Which index number [x] do you wish to pick?"
        if($index_selected -ge $index -or $index_selected -le 0){
            Write-Host "Selection is out of range" -ForegroundColor "Red"
        }else{
            $selected_vm = $vms[$index_selected -1]
            return $selected_vm
        }
    }
    catch{
        Write-Host "Invalid datatype, please input an integer" -ForegroundColor "Red"
    }

}

function Deploy-Clone([string] $confPath){
    $conf = Get-480Config -config_path $confPath
    $vm = Select-VM -folder $conf.base_folder
    $snapshot = Get-Snapshot -vm $vm -Name $conf.snapshot
    $cloneType = Read-Host "Create a [F]ull or [L]inked clone of " $vm.name
    $newName = Read-Host "Enter a name for the clone of "  $vm.name
    If ($cloneType -eq "F"){
        $linkedname = "{0}.linked" -f $vm.name
        $linkedvm = New-VM -LinkedClone -Name $linkedName -VM $vm -ReferenceSnapshot $snapshot -VMHost $conf.vm_host -Datastore $conf.datastore
        $newvm = New-VM -Name $newName -VM $linkedvm -VMHost $conf.vm_host -Datastore $conf.datastore
        $newvm | new-snapshot -Name "base" | Out-Null
        $linkedvm | Remove-VM -Confirm:$false
        Move-VM -VM $newvm -InventoryLocation $conf.output_folder | Out-Null
        Get-NetworkAdapter -VM $newvm | Set-NetworkAdapter -NetworkName $conf.default_network -StartConnected:$true -Confirm:$false | Out-Null
        }
    Elseif ($cloneType -eq "L"){
        $linkedvm = New-VM -LinkedClone -Name $newName -VM $vm -ReferenceSnapshot $snapshot -VMHost $conf.vm_host -Datastore $conf.datastore
        $linkedvm | new-snapshot -Name "base" | Out-Null
        Move-VM -VM $linkedvm -InventoryLocation $conf.output_folder | Out-Null
        Get-NetworkAdapter -VM $linkedvm | Set-NetworkAdapter -NetworkName $conf.default_network -StartConnected:$true -Confirm:$false | Out-Null
        }
    else {
        write-host "Invalid selection, program ending"
        }
}