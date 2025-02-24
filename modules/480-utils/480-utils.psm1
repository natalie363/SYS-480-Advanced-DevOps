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