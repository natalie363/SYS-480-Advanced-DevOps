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
    $selected_folder = $null
    try{
        $folders = Get-Folder -Type VM
        [int] $folder_index = 1
        Write-Host "VM Folders:"
        foreach ($folder in $folders){
            Write-Host [$folder_index] $folder
            $folder_index += 1
        }
        [int] $index_selected = Read-Host "Which folder index number [x] do you wish to pick?"
        if($index_selected -ge $folder_index -or $index_selected -le 0){
            Write-Host "Selection is out of range" -ForegroundColor "Red"
            Break
        }else{
            $selected_folder = $folders[$index_selected -1]
        }
    }
    catch{
        Write-Host "Invalid datatype, please input an integer" -ForegroundColor "Red"
        Break
    }

    try{
        Write-Host "`nVMs within" $selected_folder
        $vms = Get-VM -Location $selected_folder
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
        [int] $index_selected = Read-Host "Which VM index number [x] do you wish to pick?"
        if($index_selected -ge $index -or $index_selected -le 0){
            Write-Host "Selection is out of range" -ForegroundColor "Red"
            Break
        }else{
            $selected_vm = $vms[$index_selected -1]
            return $selected_vm
        }
    }
    catch{
        Write-Host "Invalid datatype, please input an integer" -ForegroundColor "Red"
        Break
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

function New-Network([string] $confpath){
    $conf = Get-480Config -config_path $confPath
    $net_name = Read-Host "Enter the name for your new network"
    New-VirtualSwitch -VMHost $conf.vm_host -Name $net_name
    New-VirtualPortGroup -VirtualSwitch $net_name -Name $net_name
}

function Get-NetworkDetails(){
    $selected_vm = Select-VM
    $adapter_details = Get-NetworkAdapter -VM $selected_vm 
    write-host `n"Network: " -foregroundColor Green -NoNewline
    write-host $adapter_details.NetworkName
    write-host "MAC Address: " -foregroundColor Green -NoNewline
    write-host $adapter_details.MacAddress
    write-host "IP Address: " -foregroundColor Green -NoNewline
    write-host $selected_vm.guest.ipaddress[0]
}

function Start-SingleVM(){
    $selected_vm = Select-VM
    Start-VM -VM $selected_vm
}

function Stop-SingleVM(){
    $selected_vm = Select-VM
    Stop-VM -VM $selected_vm -Confirm:$false 
}

function Set-Network(){
    $selected_vm = Select-VM
    $all_adapters = Get-NetworkAdapter -VM $selected_vm
    $networks = Get-VirtualNetwork
    [int] $net_index = 1
    Write-Host "VM Networks:"
            foreach ($network in $networks){
                Write-Host [$net_index] $network
                $net_index += 1
            }
    :label1 foreach ($adapter in $all_adapters){
        $index_selected = $null
        try{
            Write-Host "Setting adapter:" $adapter.Name -foregroundColor yellow
            Write-Host "0 or [Enter] to leave the adapter disconnected and move to the next one!"
            [int] $index_selected = Read-Host "Which network index number [x] do you wish to pick?" 
            if($index_selected -eq 0){
                continue label1
            }
            elseif($index_selected -ge $net_index -or $index_selected -le 0){
                Write-Host "Selection is out of range" -ForegroundColor "Red"
                Break
            }else{
                $selected_net = $networks[$index_selected -1]
            }
        }
        catch{
            Write-Host "Invalid datatype, please input an integer" -ForegroundColor "Red"
            Break
        }

        $adapter | Set-NetworkAdapter -NetworkName $selected_net -StartConnected:$true -Confirm:$false
    }
}
function Set-WindowsIP(){
    $selected_vm = Select-VM
    $user = Read-Host "Enter the username for" $selected_vm.name 
    $userPass = Read-Host -AsSecureString "Enter the password for $user"
    $credObject = [pscredential]::New($user,$userPass)
    $cmd1 = 'netsh interface ip set address "Ethernet0" static 10.0.5.5 255.255.255.0 10.0.5.2 1'
    $cmd2 = 'netsh interface ip set dnsservers "Ethernet0" static 10.0.5.2'
    Invoke-VMScript -VM $selected_vm -ScriptText "$cmd1 `r`n $cmd2" -GuestCredential $credObject
}
